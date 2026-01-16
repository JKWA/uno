defmodule Uno.Bot do
  alias Uno.{Card, Game, Service, Rules}
  alias Funx.Optics.Lens
  use Funx.Monad.Either

  def take_turn(%Game{} = game, player_index) do
    case decide(game, player_index) do
      {:play, card_id} ->
        Service.play_card(game.id, player_index, card_id)

      {:play_wild, card_id, color} ->
        play_wild(game, player_index, card_id, color)

      :draw ->
        Service.draw_card(game.id, player_index)
    end
  end

  def decide(%Game{} = game, player_index) do
    top_card = Game.get_card_in_play(game)
    hand = Enum.at(Lens.view!(game, Game.hands_lens()), player_index)

    hand
    |> Rules.split_hand(top_card)
    |> decide_from_split(hand)
  end

  defp decide_from_split({[], _}, _hand), do: :draw

  defp decide_from_split({[best | _], _}, hand) do
    if Rules.wild_card?(best) do
      {:play_wild, Card.get_id(best), pick_wild_color(hand)}
    else
      {:play, Card.get_id(best)}
    end
  end

  defp play_wild(game, player_index, card_id, color) do
    either game.id, as: :tuple do
      bind Service.play_card(player_index, card_id)
      bind &Service.set_wild_color(&1.id, color)
    end
  end

  defp pick_wild_color(hand) do
    hand
    |> Enum.map(&Card.get_color/1)
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
