defmodule Uno.GameTest do
  use ExUnit.Case

  alias Uno.Card
  alias Uno.Game
  alias Funx.Monad.Either

  describe "reshuffle" do
    test "succeeds when discard pile has cards beyond top" do
      game = %Game{
        draw_pile: [],
        discard_pile: [Card.new(:red, 1), Card.new(:blue, 2), Card.new(:green, 3)],
        hands: [],
        current_player: 0
      }

      result = Game.reshuffle(game)

      assert Either.right?(result)
      %{right: reshuffled} = result
      assert length(reshuffled.draw_pile) == 2
      assert length(reshuffled.discard_pile) == 1
    end

    test "fails when discard pile has only top card" do
      game = %Game{
        draw_pile: [],
        discard_pile: [Card.new(:red, 1)],
        hands: [],
        current_player: 0
      }

      result = Game.reshuffle(game)

      assert Either.left?(result)
      assert result.left == :no_cards_to_reshuffle
    end

    test "fails when discard pile is empty" do
      game = %Game{
        draw_pile: [],
        discard_pile: [],
        hands: [],
        current_player: 0
      }

      result = Game.reshuffle(game)

      assert Either.left?(result)
      assert result.left == :no_cards_to_reshuffle
    end
  end
end
