defmodule Uno.Action.ApplyWildDrawFourTest do
  use ExUnit.Case, async: true

  alias Uno.{Game, Card}
  alias Uno.Action.ApplyWildDrawFour

  defp card(color, value), do: Card.new(color, value)

  defp game(opts) do
    defaults = %Game{
      id: 1,
      draw_pile: [],
      discard_pile: [],
      hands: [],
      current_player: 0,
      direction: 1
    }

    struct!(defaults, opts)
  end

  describe "map/3" do
    test "does nothing for non-wild-draw-four cards" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      new_game = ApplyWildDrawFour.map(game, [], %{})

      assert Game.get_hands(new_game) == [[], [], []]
      assert Game.get_current_player(new_game) == 0
    end

    test "forces next player to draw four cards and skips them" do
      draw_pile = [
        card(:red, "1"),
        card(:red, "2"),
        card(:red, "3"),
        card(:red, "4"),
        card(:red, "5")
      ]

      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, draw_pile)
        |> Map.put(:discard_pile, [card(:blue, "W4")])

      new_game = ApplyWildDrawFour.map(game, [], %{})

      hands = Game.get_hands(new_game)

      assert length(Enum.at(hands, 1)) == 4
      assert Game.get_current_player(new_game) == 1
    end
  end
end
