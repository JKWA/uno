defmodule Uno.RulesTest do
  use ExUnit.Case, async: true

  alias Funx.Ord
  alias Uno.{Card, Game, Rules}

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

  defp card(color, value), do: Card.new(color, value)

  defp game_with_hands(hands) do
    %Game{
      id: 1,
      draw_pile: [],
      discard_pile: [],
      hands: hands,
      current_player: 0,
      direction: 1
    }
  end

  # ============================================================
  # CARD MATCHING AND PLAYABILITY
  # ============================================================

  describe "playable?/2" do
    test "is true when colors match" do
      top = card(:red, "5")
      hand = card(:red, "2")

      assert Rules.playable?(hand, top)
    end

    test "is true when values match" do
      top = card(:red, "5")
      hand = card(:blue, "5")

      assert Rules.playable?(hand, top)
    end

    test "is true for wild cards regardless of match" do
      top = card(:red, "5")
      wild = card(:blue, "W")

      assert Rules.playable?(wild, top)
    end

    test "is false when neither color nor value matches" do
      top = card(:red, "5")
      hand = card(:blue, "2")

      refute Rules.playable?(hand, top)
    end
  end

  # ============================================================
  # CARD EFFECTS
  # ============================================================

  describe "card type predicates" do
    test "skip_card?/1" do
      assert Rules.skip_card?(card(:red, "S"))
      refute Rules.skip_card?(card(:red, "5"))
    end

    test "reverse_card?/1" do
      assert Rules.reverse_card?(card(:red, "R"))
      refute Rules.reverse_card?(card(:red, "5"))
    end

    test "draw_two_card?/1" do
      assert Rules.draw_two_card?(card(:red, "D"))
      refute Rules.draw_two_card?(card(:red, "5"))
    end

    test "action_card?/1" do
      assert Rules.action_card?(card(:red, "S"))
      assert Rules.action_card?(card(:red, "R"))
      assert Rules.action_card?(card(:red, "D"))
      refute Rules.action_card?(card(:red, "5"))
      refute Rules.action_card?(card(:red, "W"))
    end

    test "wild_card?/1" do
      assert Rules.wild_card?(card(:blue, "W"))
      refute Rules.wild_card?(card(:blue, "W4"))
      refute Rules.wild_card?(card(:blue, "5"))
    end

    test "wild_draw_four_card?/1" do
      assert Rules.wild_draw_four_card?(card(:blue, "W4"))
      refute Rules.wild_draw_four_card?(card(:blue, "W"))
    end
  end

  # ============================================================
  # TURN AND TABLE CONDITIONS
  # ============================================================

  describe "two_player?/1" do
    test "true when exactly two players" do
      game = game_with_hands([[], []])
      assert Rules.two_player?(game)
    end

    test "false otherwise" do
      refute Rules.two_player?(game_with_hands([[]]))
      refute Rules.two_player?(game_with_hands([[], [], []]))
    end
  end

  describe "must_say_uno?/1" do
    test "true when hand has exactly one card" do
      assert Rules.must_say_uno?([card(:red, "1")])
    end

    test "false otherwise" do
      refute Rules.must_say_uno?([])
      refute Rules.must_say_uno?([card(:red, "1"), card(:blue, "2")])
    end
  end

  describe "discard_pile_has_cards?/1" do
    test "true when more than one card in discard pile" do
      game = %Game{
        id: 1,
        draw_pile: [],
        discard_pile: [card(:red, "1"), card(:blue, "2")],
        hands: [],
        current_player: 0,
        direction: 1
      }

      assert Rules.discard_pile_has_cards?(game)
    end

    test "false when only one or zero cards" do
      game = %Game{
        id: 1,
        draw_pile: [],
        discard_pile: [card(:red, "1")],
        hands: [],
        current_player: 0,
        direction: 1
      }

      refute Rules.discard_pile_has_cards?(game)

      game = %Game{
        id: 1,
        draw_pile: [],
        discard_pile: [],
        hands: [],
        current_player: 0,
        direction: 1
      }

      refute Rules.discard_pile_has_cards?(game)
    end
  end

  # ============================================================
  # ORDERING OF PLAYS
  # ============================================================

  describe "play_ord/1" do
    test "ranks action + color match highest" do
      top = card(:red, "5")
      ord = Rules.play_ord(top)

      c1 = card(:red, "S")
      c2 = card(:red, "2")

      # better card is "less than" because of desc ordering
      assert Ord.compare(c1, c2, ord) == :lt
    end

    test "ranks color match above value match" do
      top = card(:red, "5")
      ord = Rules.play_ord(top)

      color_match = card(:red, "2")
      value_match = card(:blue, "5")

      assert Ord.compare(color_match, value_match, ord) == :lt
    end

    test "ranks wild cards lower than color or value match" do
      top = card(:red, "5")
      ord = Rules.play_ord(top)

      wild = card(:blue, "W")
      value_match = card(:blue, "5")

      assert Ord.compare(value_match, wild, ord) == :lt
    end
  end

  # ============================================================
  # END OF GAME
  # ============================================================

  describe "game_over?/1" do
    test "true when any player has empty hand" do
      game = game_with_hands([[], [card(:red, "1")]])
      assert Rules.game_over?(game)
    end

    test "false when all players have cards" do
      game = game_with_hands([[card(:red, "1")], [card(:blue, "2")]])
      refute Rules.game_over?(game)
    end
  end

  describe "winner/1" do
    test "returns index of first empty hand" do
      game = game_with_hands([[card(:red, "1")], [], [card(:blue, "2")]])
      assert Rules.winner(game) == 1
    end

    test "returns nil when no winner yet" do
      game = game_with_hands([[card(:red, "1")], [card(:blue, "2")]])
      assert Rules.winner(game) == nil
    end
  end
end
