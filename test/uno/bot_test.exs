defmodule Uno.BotTest do
  use ExUnit.Case, async: true

  alias Uno.{Bot, Card, Game}

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

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

  # ------------------------------------------------------------

  describe "decide/2" do
    test "returns :draw when player has no playable cards" do
      top_card = card(:red, "5")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [card(:blue, "1"), card(:green, "2")],
            []
          ]
        )

      assert Bot.decide(g, 0) == :draw
    end

    test "returns {:play, card_id} for matching color" do
      top_card = card(:red, "5")
      playable_card = card(:red, "3")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [playable_card, card(:blue, "1")],
            []
          ]
        )

      assert {:play, card_id} = Bot.decide(g, 0)
      assert card_id == Card.id(playable_card)
    end

    test "returns {:play, card_id} for matching value" do
      top_card = card(:red, "5")
      playable_card = card(:blue, "5")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [playable_card, card(:green, "1")],
            []
          ]
        )

      assert {:play, card_id} = Bot.decide(g, 0)
      assert card_id == Card.id(playable_card)
    end

    test "returns {:play_wild, card_id, color} for wild card" do
      top_card = card(:red, "5")
      wild_card = card(:blue, "W")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [wild_card, card(:green, "1"), card(:green, "2")],
            []
          ]
        )

      assert {:play_wild, card_id, color} = Bot.decide(g, 0)
      assert card_id == Card.id(wild_card)
      # Should pick green as it's most frequent
      assert color == :green
    end

    test "returns {:play_wild, card_id, color} for wild draw four" do
      top_card = card(:red, "5")
      wild_card = card(:blue, "W4")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [wild_card, card(:yellow, "1"), card(:yellow, "2"), card(:yellow, "3")],
            []
          ]
        )

      assert {:play_wild, card_id, color} = Bot.decide(g, 0)
      assert card_id == Card.id(wild_card)
      # Should pick yellow as it's most frequent
      assert color == :yellow
    end

    test "prefers action cards with matching color over wild" do
      top_card = card(:red, "5")
      skip_card = card(:red, "S")
      wild_card = card(:blue, "W")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [wild_card, skip_card],
            []
          ]
        )

      # Skip with matching color should be preferred over wild
      assert {:play, card_id} = Bot.decide(g, 0)
      assert card_id == Card.id(skip_card)
    end

    test "decides for correct player index" do
      top_card = card(:red, "5")
      p0_card = card(:blue, "1")
      p1_card = card(:red, "9")

      g =
        game(
          discard_pile: [top_card],
          hands: [
            [p0_card],
            [p1_card]
          ]
        )

      # Player 0 has no match
      assert Bot.decide(g, 0) == :draw

      # Player 1 has a match
      assert {:play, card_id} = Bot.decide(g, 1)
      assert card_id == Card.id(p1_card)
    end
  end

  describe "pick_wild_color (via decide)" do
    test "picks most frequent color in hand" do
      top_card = card(:red, "5")
      wild_card = card(:blue, "W")

      # Only wild is playable, other cards don't match
      g =
        game(
          discard_pile: [top_card],
          hands: [
            [wild_card, card(:green, "1"), card(:green, "2"), card(:green, "3")],
            []
          ]
        )

      assert {:play_wild, _card_id, :green} = Bot.decide(g, 0)
    end

    test "handles tie by picking one of the tied colors" do
      top_card = card(:red, "5")
      wild_card = card(:blue, "W")

      # Only wild is playable
      g =
        game(
          discard_pile: [top_card],
          hands: [
            [wild_card, card(:green, "1"), card(:yellow, "2")],
            []
          ]
        )

      assert {:play_wild, _card_id, color} = Bot.decide(g, 0)
      assert color in [:green, :yellow, :blue]
    end
  end
end
