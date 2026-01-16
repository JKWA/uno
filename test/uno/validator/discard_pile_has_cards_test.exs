defmodule Uno.Validator.DiscardPileHasCardsTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Uno.{Card, Game}
  alias Uno.Validator.DiscardPileHasCards

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

  describe "validate/3" do
    test "returns Right when discard pile has more than one card" do
      g = game(discard_pile: [card(:red, "1"), card(:blue, "2")])

      result = DiscardPileHasCards.validate(g, [], %{})

      assert Either.right?(result)
    end

    test "returns Left when discard pile has only one card" do
      g = game(discard_pile: [card(:red, "1")])

      result = DiscardPileHasCards.validate(g, [], %{})

      assert Either.left?(result)
    end

    test "returns Left when discard pile is empty" do
      g = game(discard_pile: [])

      result = DiscardPileHasCards.validate(g, [], %{})

      assert Either.left?(result)
    end

    test "error message indicates no cards to reshuffle" do
      g = game(discard_pile: [card(:red, "1")])

      result = DiscardPileHasCards.validate(g, [], %{})

      assert %Funx.Monad.Either.Left{left: error} = result
      assert error.errors == ["no cards to reshuffle"]
    end
  end
end
