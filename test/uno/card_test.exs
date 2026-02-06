defmodule Uno.CardTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Uno.Card

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

  # defp card(color, value), do: Card.new(color, value)

  # ============================================================
  # CONSTRUCTION
  # ============================================================

  describe "new/2" do
    test "creates a valid card with id, color, and value" do
      card = Card.new(:red, "5")

      assert is_binary(Card.id(card))
      assert Card.color(card) == :red
      assert Card.value(card) == "5"
    end

    test "raises for invalid color" do
      assert_raise Funx.Errors.ValidationError, fn ->
        Card.new(:purple, "5")
      end
    end

    test "raises for invalid value" do
      assert_raise Funx.Errors.ValidationError, fn ->
        Card.new(:red, "X")
      end
    end
  end

  # ============================================================
  # CONSTANTS
  # ============================================================

  describe "colors/0" do
    test "exposes valid colors" do
      assert Card.colors() == [:red, :blue, :green, :yellow]
    end
  end

  describe "values/0" do
    test "includes number, action, and wild values" do
      values = Card.values()

      assert "0" in values
      assert "9" in values
      assert "S" in values
      assert "R" in values
      assert "D" in values
      assert "W" in values
      assert "W4" in values
    end
  end

  describe "actions/0" do
    test "exposes action card values" do
      assert Card.actions() == ["S", "R", "D"]
    end
  end

  describe "wilds/0" do
    test "exposes wild card values" do
      assert Card.wilds() == ["W", "W4"]
    end
  end

  # ============================================================
  # LENSES AND ACCESSORS
  # ============================================================

  describe "getters" do
    test "id/1, color/1, value/1" do
      card = Card.new(:green, "D")

      assert Card.color(card) == :green
      assert Card.value(card) == "D"
      assert is_binary(Card.id(card))
    end
  end

  # ============================================================
  # VALIDATION
  # ============================================================

  describe "validate_card/0" do
    test "passes for valid card" do
      card = Card.new(:red, "5")
      result = Either.validate(card, Card.validate_card())

      assert Either.right(card) == result
    end

    test "fails for invalid value" do
      bad = %Card{id: "1", color: :red, value: "X"}

      result = Either.validate(bad, Card.validate_card())

      assert Either.left?(result)
    end

    test "fails for invalid color" do
      bad = %Card{id: "1", color: :purple, value: "5"}

      result = Either.validate(bad, Card.validate_card())

      assert Either.left?(result)
    end
  end

  # ============================================================
  # EQUALITY
  # ============================================================

  describe "color_eq/0" do
    test "treats cards with same color as equal" do
      c1 = Card.new(:red, "1")
      c2 = Card.new(:red, "9")

      assert Funx.Eq.eq?(c1, c2, Card.color_eq())
    end

    test "treats cards with different color as not equal" do
      c1 = Card.new(:red, "1")
      c2 = Card.new(:blue, "1")

      refute Funx.Eq.eq?(c1, c2, Card.color_eq())
    end
  end

  describe "value_eq/0" do
    test "treats cards with same value as equal" do
      c1 = Card.new(:red, "5")
      c2 = Card.new(:blue, "5")

      assert Funx.Eq.eq?(c1, c2, Card.value_eq())
    end

    test "treats cards with different value as not equal" do
      c1 = Card.new(:red, "5")
      c2 = Card.new(:red, "6")

      refute Funx.Eq.eq?(c1, c2, Card.value_eq())
    end
  end

  describe "card_eq/0" do
    test "treats cards equal when both color and value match" do
      c1 = Card.new(:red, "5")
      c2 = %Card{id: "x", color: :red, value: "5"}

      assert Funx.Eq.eq?(c1, c2, Card.card_eq())
    end

    test "treats cards not equal when either color or value differs" do
      c1 = Card.new(:red, "5")
      c2 = Card.new(:blue, "5")

      refute Funx.Eq.eq?(c1, c2, Card.card_eq())
    end
  end

  # ============================================================
  # ORDERING
  # ============================================================

  describe "color_ord/0" do
    test "orders by color ascending" do
      red = Card.new(:red, "5")
      yellow = Card.new(:yellow, "5")

      assert Funx.Ord.compare(red, yellow, Card.color_ord()) == :lt
    end
  end

  describe "value_ord/0" do
    test "orders by value ascending" do
      five = Card.new(:red, "5")
      nine = Card.new(:red, "9")

      assert Funx.Ord.compare(five, nine, Card.value_ord()) == :lt
    end
  end

  describe "card_ord/0" do
    test "orders by color first, then value descending" do
      c1 = Card.new(:blue, "2")
      c2 = Card.new(:blue, "9")

      assert Funx.Ord.compare(c2, c1, Card.card_ord()) == :gt
    end

    test "color dominates value in ordering" do
      c1 = Card.new(:blue, "9")
      c2 = Card.new(:red, "1")

      assert Funx.Ord.compare(c2, c1, Card.card_ord()) == :gt
    end
  end

  describe "ord_for uses card_ord" do
    test "orders by color first, then value descending" do
      c1 = Card.new(:blue, "2")
      c2 = Card.new(:blue, "9")

      assert Funx.Ord.compare(c2, c1) == :gt
    end

    test "color dominates value in ordering" do
      c1 = Card.new(:blue, "9")
      c2 = Card.new(:red, "1")

      assert Funx.Ord.compare(c2, c1) == :gt
    end
  end
end
