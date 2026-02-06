defmodule Uno.Action.ApplyReverseTest do
  use ExUnit.Case, async: true

  alias Uno.Action.ApplyReverse
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
    test "does nothing for non-reverse cards" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      new_game = ApplyReverse.map(game, [], %{})

      assert Game.direction(new_game) == 1
      assert Game.current_player(new_game) == 0
    end

    test "reverses direction in games with more than two players" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "R")])

      new_game = ApplyReverse.map(game, [], %{})

      assert Game.direction(new_game) == -1
    end

    test "acts like skip in a two-player game" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:red, "R")])

      new_game = ApplyReverse.map(game, [], %{})

      assert Game.current_player(new_game) == 1
    end
  end
end
