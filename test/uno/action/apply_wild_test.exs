defmodule Uno.Action.ApplyWildTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Funx.Monad.Either.Right
  alias Uno.Action.ApplyWild
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

  describe "bind/3" do
    test "returns game unchanged for non-wild cards" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      result = ApplyWild.bind(game, [color: :green], %{})

      assert %Right{right: new_game} = result
      assert Game.card_in_play(new_game).color == :red
    end

    test "sets wild color when color is provided" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:blue, "W")])

      result = ApplyWild.bind(game, [color: :red], %{})

      assert %Right{right: new_game} = result
      assert Game.card_in_play(new_game).color == :red
    end

    test "returns game unchanged for wild draw four cards" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:blue, "W4")])

      result = ApplyWild.bind(game, [color: :yellow], %{})

      assert %Right{right: new_game} = result
      assert Game.card_in_play(new_game).color == :blue
    end

    test "returns error when color is nil for wild card" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:blue, "W")])

      result = ApplyWild.bind(game, [color: nil], %{})

      assert Either.left?(result)
    end

    test "returns error when color is invalid for wild card" do
      game =
        game(hands: [[], []])
        |> Map.put(:discard_pile, [card(:blue, "W")])

      result = ApplyWild.bind(game, [color: :purple], %{})

      assert Either.left?(result)
    end
  end
end
