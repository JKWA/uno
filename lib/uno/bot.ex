defmodule Uno.Bot do
  alias Funx.Optics.Lens
  alias Uno.{Card, Game, Hand, Rules, Service}

  @type decision ::
          :draw
          | {:play, String.t()}
          | {:play_wild, String.t(), atom()}

  @spec take_turn(Game.t(), non_neg_integer()) ::
          {:ok, Game.t()} | {:error, any()}
  def take_turn(%Game{} = game, player_index) do
    case decide(game, player_index) do
      {:play, card_id} ->
        Service.play_card(game.id, player_index, card_id)

      {:play_wild, card_id, color} ->
        Service.play_card(game.id, player_index, card_id, color)

      :draw ->
        Service.draw_card(game.id, player_index)
    end
  end

  @spec decide(Game.t(), non_neg_integer()) :: decision()
  def decide(%Game{} = game, player_index) do
    top_card = Game.card_in_play(game)
    hand = Enum.at(Lens.view!(game, Game.hands_lens()), player_index)

    hand
    |> Hand.split_playable(top_card)
    |> decide_from_split()
  end

  @spec decide_from_split({[Card.t()], [Card.t()]}) :: decision()
  defp decide_from_split({[], _}), do: :draw

  defp decide_from_split({[best | _] = playable, not_playable}) do
    if Rules.any_wild_card?(best) do
      {:play_wild, Card.id(best), pick_wild_color(playable ++ not_playable)}
    else
      {:play, Card.id(best)}
    end
  end

  @spec pick_wild_color([Card.t()]) :: atom()
  defp pick_wild_color(hand) do
    hand
    |> Enum.map(&Card.color/1)
    |> case do
      [] ->
        Enum.random(Card.colors())

      colors ->
        colors
        |> Enum.frequencies()
        |> Enum.max_by(fn {_color, count} -> count end)
        |> elem(0)
    end
  end
end
