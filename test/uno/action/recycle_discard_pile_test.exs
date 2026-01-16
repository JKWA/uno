defmodule Uno.Action.RecycleDiscardPileTest do
  use ExUnit.Case, async: true

  alias Uno.Action.RecycleDiscardPile
  alias Uno.{Card, Game}

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

  describe "map/3" do
    test "moves all but top card from discard pile to draw pile" do
      top = card(:red, "1")
      rest = [card(:blue, "2"), card(:green, "3"), card(:yellow, "4")]
      discard = [top | rest]

      game = game(discard_pile: discard, draw_pile: [])

      new_game = RecycleDiscardPile.map(game, [], %{})

      assert Game.get_discard_pile(new_game) == [top]
      assert Game.get_draw_pile(new_game) == rest
    end

    test "replaces existing draw pile with recycled cards" do
      top = card(:red, "1")
      rest = [card(:blue, "2"), card(:green, "3")]
      discard = [top | rest]
      existing_draw = [card(:yellow, "9")]

      game = game(discard_pile: discard, draw_pile: existing_draw)

      new_game = RecycleDiscardPile.map(game, [], %{})

      assert Game.get_discard_pile(new_game) == [top]
      assert Game.get_draw_pile(new_game) == rest
    end

    test "does not modify other game state" do
      top = card(:red, "1")
      rest = [card(:blue, "2")]
      discard = [top | rest]
      hands = [[card(:green, "3")], [card(:yellow, "7")]]

      game = game(discard_pile: discard, hands: hands, current_player: 1)

      new_game = RecycleDiscardPile.map(game, [], %{})

      assert Game.get_hands(new_game) == hands
      assert Game.get_current_player(new_game) == 1
    end

    test "handles discard pile with only one card (results in empty draw pile)" do
      top = card(:red, "1")
      game = game(discard_pile: [top], draw_pile: [])

      new_game = RecycleDiscardPile.map(game, [], %{})

      assert Game.get_discard_pile(new_game) == [top]
      assert Game.get_draw_pile(new_game) == []
    end
  end
end
