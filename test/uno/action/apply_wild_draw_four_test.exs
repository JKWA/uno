defmodule Uno.Action.ApplyWildDrawFourTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Funx.Monad.Either.Right
  alias Uno.Action.ApplyWildDrawFour
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
    test "returns game unchanged for non-wild-draw-four cards" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:discard_pile, [card(:red, "5")])

      result = ApplyWildDrawFour.bind(game, [color: nil], %{})

      assert %Right{right: new_game} = result
      assert Game.get_hands(new_game) == [[], [], []]
      assert Game.get_current_player(new_game) == 0
    end

    test "sets wild color and forces next player to draw four cards and skips them" do
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

      result = ApplyWildDrawFour.bind(game, [color: :green], %{})

      assert %Right{right: new_game} = result
      assert Game.get_card_in_play(new_game).color == :green
      assert length(Enum.at(Game.get_hands(new_game), 1)) == 4
      assert Game.get_current_player(new_game) == 1
    end

    test "returns error when color is nil for wild draw four" do
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

      result = ApplyWildDrawFour.bind(game, [color: nil], %{})

      assert Either.left?(result)
    end

    test "returns error when color is invalid for wild draw four" do
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

      result = ApplyWildDrawFour.bind(game, [color: :purple], %{})

      assert Either.left?(result)
    end

    test "reshuffles discard pile when draw pile is empty" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, [])
        |> Map.put(:discard_pile, [
          card(:blue, "W4"),
          card(:red, "1"),
          card(:red, "2"),
          card(:red, "3"),
          card(:red, "4"),
          card(:red, "5")
        ])

      result = ApplyWildDrawFour.bind(game, [color: :green], %{})

      assert %Right{right: new_game} = result
      assert length(Enum.at(Game.get_hands(new_game), 1)) == 4
      assert Game.get_current_player(new_game) == 1
    end

    test "raises when not enough cards even after reshuffle" do
      game =
        game(hands: [[], [], []])
        |> Map.put(:draw_pile, [])
        |> Map.put(:discard_pile, [card(:blue, "W4"), card(:red, "1"), card(:red, "2")])

      assert_raise Funx.Errors.ValidationError, fn ->
        ApplyWildDrawFour.bind(game, [color: :green], %{})
      end
    end
  end
end
