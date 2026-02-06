defmodule Uno.Validator.ValidPlayTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Uno.{Card, Game}
  alias Uno.Validator.ValidPlay

  defp card(color, value), do: Card.new(color, value)

  defp game(top_card, player_hand) do
    %Game{
      id: 1,
      draw_pile: [],
      discard_pile: [top_card],
      hands: [player_hand, []],
      current_player: 0,
      direction: 1
    }
  end

  describe "validate/3" do
    test "returns Right when card matches by color" do
      top = card(:red, "5")
      hand_card = card(:red, "2")
      g = game(top, [hand_card])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(hand_card)], %{})

      assert Either.right?(result)
    end

    test "returns Right when card matches by value" do
      top = card(:red, "5")
      hand_card = card(:blue, "5")
      g = game(top, [hand_card])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(hand_card)], %{})

      assert Either.right?(result)
    end

    test "returns Right when card is a wild" do
      top = card(:red, "5")
      wild = card(:blue, "W")
      g = game(top, [wild])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(wild)], %{})

      assert Either.right?(result)
    end

    test "returns Right when card is a wild draw four" do
      top = card(:red, "5")
      wild4 = card(:blue, "W4")
      g = game(top, [wild4])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(wild4)], %{})

      assert Either.right?(result)
    end

    test "returns Left when card does not match" do
      top = card(:red, "5")
      hand_card = card(:blue, "2")
      g = game(top, [hand_card])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(hand_card)], %{})

      assert Either.left?(result)
    end

    test "error message indicates card must match" do
      top = card(:red, "5")
      hand_card = card(:blue, "2")
      g = game(top, [hand_card])

      result = ValidPlay.validate(g, [player_index: 0, card_id: Card.id(hand_card)], %{})

      assert %Funx.Monad.Either.Left{left: error} = result
      assert error.errors == ["card must match by color or value"]
    end
  end
end
