defmodule UnoWeb.Game.Index do
  use UnoWeb, :live_view

  import UnoWeb.Components.PlayerPanel
  import UnoWeb.Components.CardFace

  alias Uno.{Game, GameServer, Rules}

  def mount(%{"id" => id}, _session, socket) do
    game_id = String.to_integer(id)

    case GameServer.ensure_started(game_id) do
      :ok ->
        game = GameServer.state(game_id)
        Phoenix.PubSub.subscribe(Uno.PubSub, "game:#{game_id}")

        bots = GameServer.bots(game_id)

        {:ok,
         socket
         |> assign(game_id: game_id, game: game)
         |> assign_bots(bots)
         |> assign_view()
         |> print_game_state()}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  defp assign_view(socket) do
    assign(socket, view_model(socket.assigns.game))
  end

  defp view_model(game) do
    top_card = Game.card_in_play(game)
    p1_hand = Game.hand(game, 0)
    p2_hand = Game.hand(game, 1)

    %{
      top_card: top_card,
      p1_hand: p1_hand,
      p1_playable_ids: Rules.playable_ids(p1_hand, top_card),
      p2_hand: p2_hand,
      p2_playable_ids: Rules.playable_ids(p2_hand, top_card),
      p1_uno: Rules.must_say_uno?(p1_hand),
      p2_uno: Rules.must_say_uno?(p2_hand),
      game_over: Rules.game_over?(game),
      winner: Rules.winner(game)
    }
  end

  defp assign_bots(socket, bots) do
    assign(socket, p1_bot: MapSet.member?(bots, 0), p2_bot: MapSet.member?(bots, 1))
  end

  def handle_event("play_card", %{"player" => player, "card_id" => card_id}, socket) do
    player_index = String.to_integer(player)
    card = Game.card_in_hand(socket.assigns.game, player_index, card_id)

    if Rules.any_wild_card?(card) do
      {:noreply, push_event(socket, "prompt_wild_color", %{player: player, card_id: card_id})}
    else
      GameServer.play_card(socket.assigns.game_id, player_index, card_id)
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

    GameServer.play_card(socket.assigns.game_id, player_index, card_id, color_atom)
    |> handle_result(socket)
  end

  def handle_event("draw_card", %{"player" => player}, socket) do
    player_index = String.to_integer(player)

    GameServer.draw_card(socket.assigns.game_id, player_index)
    |> handle_result(socket)
  end

  def handle_event("toggle_bot", %{"player" => player}, socket) do
    player_index = String.to_integer(player)
    bots = GameServer.toggle_bot(socket.assigns.game_id, player_index)

    {:noreply, assign_bots(socket, bots)}
  end

  def handle_event("redeal", _params, socket) do
    game = GameServer.redeal(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(game: game)
     #  |> assign_bots(MapSet.new([1]))
     |> assign_view()
     |> print_game_state()}
  end

  def handle_info({:bots_updated, bots}, socket) do
    {:noreply, assign_bots(socket, bots)}
  end

  def handle_info({:game_updated, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)
     |> assign_view()
     |> print_game_state()}
  end

  defp handle_result({:ok, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)
     |> assign_view()
     |> print_game_state()}
  end

  defp handle_result({:error, reason}, socket) do
    {:noreply, put_flash(socket, :error, format_error(reason))}
  end

  defp print_game_state(socket) do
    game = socket.assigns.game
    push_event(socket, "print_game_state", %{game: inspect(game, pretty: true)})
  end

  defp format_error(%Funx.Errors.ValidationError{errors: errors}) do
    Enum.join(errors, ", ")
  end

  defp format_error(reason), do: inspect(reason)
end
