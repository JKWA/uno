defmodule UnoWeb.Game.Index do
  use UnoWeb, :live_view

  import UnoWeb.Components.PlayerPanel
  import UnoWeb.Components.CardFace

  alias Uno.{Bot, Game, Rules, Service}

  def mount(_params, _session, socket) do
    game = Service.create()

    {:ok,
     socket
     |> assign(game: game)
     |> assign_view()}
  end

  defp assign_view(socket) do
    assign(socket, view_model(socket.assigns.game))
  end

  defp view_model(game) do
    top_card = Game.get_card_in_play(game)
    p1_hand = Game.get_hand(game, 0)
    p2_hand = Game.get_hand(game, 1)

    %{
      top_card: top_card,
      p1_hand: p1_hand,
      p1_playable_ids: playable_ids(p1_hand, top_card),
      p2_hand: p2_hand,
      p2_playable_ids: playable_ids(p2_hand, top_card),
      p1_uno: Rules.must_say_uno?(p1_hand),
      p2_uno: Rules.must_say_uno?(p2_hand),
      game_over: Rules.game_over?(game),
      winner: Rules.winner(game)
    }
  end

  defp playable_ids(hand, top_card) do
    hand
    |> Enum.filter(&Rules.playable?(&1, top_card))
    |> MapSet.new(& &1.id)
  end

  def handle_event("play_card", %{"player" => player, "card_id" => card_id}, socket) do
    player_index = String.to_integer(player)
    card = Game.get_card_in_hand(socket.assigns.game, player_index, card_id)

    if Rules.any_wild_card?(card) do
      {:noreply, push_event(socket, "prompt_wild_color", %{player: player, card_id: card_id})}
    else
      Service.play_card(socket.assigns.game.id, player_index, card_id)
      |> handle_result(socket)
    end
  end

  def handle_event(
        "play_wild",
        %{"player" => player, "card_id" => card_id, "color" => color},
        socket
      ) do
    player_index = String.to_integer(player)

    # NOTE: It's unsafe to just convert user input string to atom!
    # We are doing this to illustrate downstream validation.
    color_atom = if color, do: String.to_atom(color), else: nil

    Service.play_card(socket.assigns.game.id, player_index, card_id, color_atom)
    |> handle_result(socket)
  end

  def handle_event("draw_card", %{"player" => player}, socket) do
    player_index = String.to_integer(player)

    Service.draw_card(socket.assigns.game.id, player_index)
    |> handle_result(socket)
  end

  def handle_event("new_game", _params, socket) do
    game = Service.create()

    {:noreply,
     socket
     |> put_flash(:info, "New game started")
     |> assign(game: game)
     |> assign_view()
     |> maybe_bot()}
  end

  def handle_info(:bot_turn, socket) do
    game = socket.assigns.game

    if game.current_player == 1 and not Rules.game_over?(game) do
      Bot.take_turn(game, 1)
      |> handle_result(socket)
    else
      {:noreply, socket}
    end
  end

  defp handle_result({:ok, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)
     |> assign_view()
     |> maybe_bot()}
  end

  defp handle_result({:error, reason}, socket) do
    {:noreply, put_flash(socket, :error, format_error(reason))}
  end

  defp maybe_bot(socket) do
    game = socket.assigns.game

    if game.current_player == 1 and not Rules.game_over?(game) do
      Process.send_after(self(), :bot_turn, 1200)
    end

    socket
  end

  defp format_error(%Funx.Errors.ValidationError{errors: errors}) do
    Enum.join(errors, ", ")
  end

  defp format_error(reason), do: inspect(reason)
end
