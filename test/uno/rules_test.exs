defmodule Uno.RulesTest do
  use ExUnit.Case

  alias Uno.Card
  alias Uno.Rules
  alias Funx.Monad.Either

  describe "playable_card" do
    test "playable if same color" do
      top = Card.new(:red, 5)
      hand = Card.new(:red, 2)
      assert Funx.Eq.eq?(top, hand, Rules.playable_card())
      assert Either.right?(Either.validate(hand, Rules.card_match(top)))
    end

    test "playable if same value" do
      top = Card.new(:red, 5)
      hand = Card.new(:blue, 5)
      assert Funx.Eq.eq?(top, hand, Rules.playable_card())
      assert Either.right?(Either.validate(hand, Rules.card_match(top)))
    end

    test "not playable if different color and value" do
      top = Card.new(:red, 5)
      hand = Card.new(:blue, 3)
      refute Funx.Eq.eq?(top, hand, Rules.playable_card())
      assert Either.left?(Either.validate(hand, Rules.card_match(top)))
    end
  end
end
