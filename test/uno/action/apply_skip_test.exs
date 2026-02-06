defmodule Uno.Action.ApplySkipTest do
  use ExUnit.Case, async: true

  alias Uno.Action.ApplySkip
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
    test "does nothing for non-skip cards" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      new_game = ApplySkip.map(game, [], %{})

      assert Game.current_player(new_game) == 0
    end

    test "skips the next player" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "S")])

      new_game = ApplySkip.map(game, [], %{})

      assert Game.current_player(new_game) == 1
    end
  end
end
