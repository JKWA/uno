defmodule Uno.Action.ApplyDrawTwoTest do
  use ExUnit.Case, async: true

  alias Uno.Action.ApplyDrawTwo
  alias Uno.{Card, Game}

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
    test "does nothing for non-draw-two cards" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      new_game = ApplyDrawTwo.map(game, [], %{})

      assert Game.get_hands(new_game) == [[], [], []]
      assert Game.get_current_player(new_game) == 0
    end

    test "forces next player to draw two cards and skips them" do
      draw_pile = [card(:blue, "1"), card(:green, "2"), card(:yellow, "3")]

      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, draw_pile)
        |> Map.put(:discard_pile, [card(:red, "D")])

      new_game = ApplyDrawTwo.map(game, [], %{})

      hands = Game.get_hands(new_game)

      assert length(Enum.at(hands, 1)) == 2
      assert Game.get_current_player(new_game) == 1
    end

    test "reshuffles discard pile when draw pile is empty" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, [])
        |> Map.put(:discard_pile, [
          card(:red, "D"),
          card(:blue, "1"),
          card(:green, "2"),
          card(:yellow, "3")
        ])

      new_game = ApplyDrawTwo.map(game, [], %{})

      hands = Game.get_hands(new_game)

      assert length(Enum.at(hands, 1)) == 2
      assert Game.get_current_player(new_game) == 1
    end

    test "raises when not enough cards even after reshuffle" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, [])
        |> Map.put(:discard_pile, [card(:red, "D"), card(:blue, "1")])

      assert_raise Funx.Errors.ValidationError, fn ->
        ApplyDrawTwo.map(game, [], %{})
      end
    end
  end
end
