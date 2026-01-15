defmodule Uno.CardTest do
  use ExUnit.Case

  alias Uno.Card
  alias Funx.Monad.Either

  describe "Card.new/2" do
    test "creates a card with color and value" do
      card = Card.new(:red, 5)
      assert card.color == :red
      assert card.value == 5
    end
  end

  describe "Card.validate_card/0" do
    test "valid card passes validation" do
      card = Card.new(:red, 5)
      assert Either.right(card) == Either.validate(card, Card.validate_card())
    end

    test "all valid colors pass validation" do
      for color <- [:red, :blue, :green, :yellow] do
        card = Card.new(color, 0)
        assert Either.right(card) == Either.validate(card, Card.validate_card())
      end
    end

    test "all valid values pass validation" do
      for value <- 0..9 do
        card = Card.new(:red, value)
        assert Either.right(card) == Either.validate(card, Card.validate_card())
      end
    end

    test "invalid color fails validation" do
      card = %Card{color: :purple, value: 5}
      assert Either.left?(Either.validate(card, Card.validate_card()))
    end

    test "invalid value below range fails validation" do
      card = %Card{color: :red, value: -1}
      assert Either.left?(Either.validate(card, Card.validate_card()))
    end

    test "invalid value above range fails validation" do
      card = %Card{color: :red, value: 10}
      assert Either.left?(Either.validate(card, Card.validate_card()))
    end

    test "nil color fails validation" do
      card = %Card{color: nil, value: 5}
      assert Either.left?(Either.validate(card, Card.validate_card()))
    end

    test "nil value fails validation" do
      card = %Card{color: :red, value: nil}
      assert Either.left?(Either.validate(card, Card.validate_card()))
    end
  end

  describe "equality" do
    test "same color and value are equal" do
      a = Card.new(:red, 5)
      b = Card.new(:red, 5)
      assert Funx.Eq.eq?(a, b)
    end

    test "different color not equal" do
      a = Card.new(:red, 5)
      b = Card.new(:blue, 5)
      refute Funx.Eq.eq?(a, b)
    end

    test "different value not equal" do
      a = Card.new(:red, 5)
      b = Card.new(:red, 3)
      refute Funx.Eq.eq?(a, b)
    end
  end

  # describe "ordering" do
  #   test "orders by color first" do
  #     red = Card.new(:red, 9)
  #     blue = Card.new(:blue, 0)
  #     assert Funx.Ord.compare(red, blue, Card.color_ord) == :lt
  #   end

  #   test "same color orders by value" do
  #     low = Card.new(:green, 2)
  #     high = Card.new(:green, 7)
  #     assert Funx.Ord.compare(low, high) == :lt
  #   end
  # end
end
