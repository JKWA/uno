defmodule Uno.Action.DrawForPlayerTest do
  use ExUnit.Case

  alias Funx.Monad.Either
  alias Funx.Monad.Either.Right
  alias Uno.Action.DrawForPlayer
  alias Uno.Card
  alias Uno.Game

  describe "bind/3" do
    test "draws card from draw pile when available" do
      card_to_draw = Card.new(:red, "5")

      game = %Game{
        draw_pile: [card_to_draw, Card.new(:blue, "3")],
        discard_pile: [Card.new(:green, "1")],
        hands: [[], []],
        current_player: 0
      }

      result = DrawForPlayer.bind(game, [player_index: 0], %{})

      assert Either.right?(result)
      %{right: updated_game} = result
      assert length(updated_game.draw_pile) == 1
      assert length(Enum.at(updated_game.hands, 0)) == 1
      assert hd(Enum.at(updated_game.hands, 0)) == card_to_draw
    end

    test "draws card for specified player index" do
      card_to_draw = Card.new(:red, "5")

      game = %Game{
        draw_pile: [card_to_draw],
        discard_pile: [Card.new(:green, "1")],
        hands: [[], []],
        current_player: 0
      }

      result = DrawForPlayer.bind(game, [player_index: 1], %{})

      assert Either.right?(result)
      %Right{right: updated_game} = result
      assert Enum.at(updated_game.hands, 0) == []
      assert Enum.at(updated_game.hands, 1) == [card_to_draw]
    end

    test "reshuffles and draws when draw pile is empty" do
      game = %Game{
        draw_pile: [],
        discard_pile: [Card.new(:red, "1"), Card.new(:blue, "2"), Card.new(:green, "3")],
        hands: [[], []],
        current_player: 0
      }

      result = DrawForPlayer.bind(game, [player_index: 0], %{})

      assert Either.right?(result)
      %Right{right: updated_game} = result
      # One card went to discard (top stays), one to hand, one in draw pile
      assert length(updated_game.discard_pile) == 1
      assert length(Enum.at(updated_game.hands, 0)) == 1
      # Draw pile should have remaining cards minus the one drawn
      assert length(updated_game.draw_pile) == 1
    end

    test "fails when draw pile empty and discard has only top card" do
      game = %Game{
        draw_pile: [],
        discard_pile: [Card.new(:red, "1")],
        hands: [[], []],
        current_player: 0
      }

      result = DrawForPlayer.bind(game, [player_index: 0], %{})

      assert Either.left?(result)
    end

    test "fails when both piles are empty" do
      game = %Game{
        draw_pile: [],
        discard_pile: [],
        hands: [[], []],
        current_player: 0
      }

      result = DrawForPlayer.bind(game, [player_index: 0], %{})

      assert Either.left?(result)
    end
  end
end
