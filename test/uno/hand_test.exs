defmodule Uno.HandTest do
  use ExUnit.Case, async: true

  alias Uno.{Card, Hand}

  defp card(color, value), do: Card.new(color, value)

  defp has_card?(cards, color, value) do
    Enum.any?(cards, fn c ->
      Card.get_color(c) == color and Card.get_value(c) == value
    end)
  end

  # ============================================================
  # BASIC ACCESS AND STRUCTURE
  # ============================================================

  describe "get_card/2" do
    test "finds card by id" do
      c1 = card(:red, "5")
      c2 = card(:blue, "3")
      hand = [c1, c2]

      assert Hand.get_card(hand, Card.get_id(c1)) == c1
      assert Hand.get_card(hand, Card.get_id(c2)) == c2
    end

    test "raises an error when card not found" do
      hand = [card(:red, "5")]

      assert_raise RuntimeError, fn ->
        Hand.get_card(hand, "nonexistent")
      end
    end
  end

  describe "remove_card/2" do
    test "removes card by id" do
      c1 = card(:red, "5")
      c2 = card(:blue, "3")
      hand = [c1, c2]

      result = Hand.remove_card(hand, Card.get_id(c1))

      assert length(result) == 1
      assert hd(result) == c2
    end
  end

  describe "add_card/2" do
    test "adds card to front of hand" do
      c1 = card(:red, "5")
      c2 = card(:blue, "3")
      hand = [c1]

      result = Hand.add_card(hand, c2)

      assert length(result) == 2
      assert hd(result) == c2
    end
  end

  describe "sort/1" do
    test "sorts hand by card ordering" do
      hand = [
        card(:yellow, "3"),
        card(:blue, "1"),
        card(:red, "5")
      ]

      sorted = Hand.sort(hand)

      # Cards should be sorted by color then value
      assert Card.get_color(hd(sorted)) == :blue
    end
  end

  # ============================================================
  # HAND-SPECIFIC QUESTIONS
  # ============================================================

  describe "empty?/1" do
    test "true when hand is empty" do
      assert Hand.empty?([])
    end

    test "false when hand has cards" do
      refute Hand.empty?([card(:red, "5")])
    end
  end

  # ============================================================
  # OPERATIONS THAT RESHAPE A HAND
  # ============================================================

  describe "split_playable/2" do
    test "splits hand into playable and not playable" do
      top = card(:red, "5")

      hand = [
        card(:red, "2"),
        card(:blue, "5"),
        card(:blue, "3"),
        card(:green, "W")
      ]

      {playable, not_playable} = Hand.split_playable(hand, top)

      assert length(playable) == 3
      assert length(not_playable) == 1

      assert has_card?(playable, :red, "2")
      assert has_card?(playable, :blue, "5")
      assert has_card?(playable, :green, "W")

      assert has_card?(not_playable, :blue, "3")
    end

    test "sorts playable cards with action + color match first" do
      top = card(:red, "5")

      hand = [
        card(:red, "2"),
        card(:red, "S"),
        card(:blue, "5"),
        card(:green, "W")
      ]

      {playable, _not_playable} = Hand.split_playable(hand, top)

      # Action card with color match should be first
      first = hd(playable)
      assert Card.get_value(first) == "S"
      assert Card.get_color(first) == :red
    end
  end

  describe "sort_by_playability/2" do
    test "puts stronger plays earlier" do
      top = card(:red, "5")

      hand = [
        card(:blue, "3"),
        card(:red, "2"),
        card(:blue, "5"),
        card(:red, "S")
      ]

      sorted = Hand.sort_by_playability(hand, top)

      # The best card should come first
      first = hd(sorted)

      assert Card.get_value(first) == "S"
      assert Card.get_color(first) == :red

      # The worst card should be last
      last = List.last(sorted)

      assert Card.get_color(last) == :blue
      assert Card.get_value(last) == "3"
    end
  end
end
