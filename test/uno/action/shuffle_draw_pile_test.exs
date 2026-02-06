defmodule Uno.Action.ShuffleDrawPileTest do
  use ExUnit.Case, async: true

  alias Uno.Action.ShuffleDrawPile
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
    test "shuffles the draw pile" do
      cards = for i <- 1..9, do: card(:red, Integer.to_string(i))
      game = game(draw_pile: cards)

      new_game = ShuffleDrawPile.map(game, [], %{})

      # The draw pile should contain the same cards
      assert Enum.sort(Game.draw_pile(new_game)) == Enum.sort(cards)
      assert length(Game.draw_pile(new_game)) == 9
    end

    test "does not modify other game state" do
      cards = for i <- 1..5, do: card(:red, Integer.to_string(i))
      discard = [card(:blue, "5")]
      hands = [[card(:green, "3")], [card(:yellow, "7")]]

      game = game(draw_pile: cards, discard_pile: discard, hands: hands, current_player: 1)

      new_game = ShuffleDrawPile.map(game, [], %{})

      assert Game.discard_pile(new_game) == discard
      assert Game.hands(new_game) == hands
      assert Game.current_player(new_game) == 1
    end

    test "handles empty draw pile" do
      game = game(draw_pile: [])

      new_game = ShuffleDrawPile.map(game, [], %{})

      assert Game.draw_pile(new_game) == []
    end

    test "handles single card draw pile" do
      c1 = card(:red, "1")
      game = game(draw_pile: [c1])

      new_game = ShuffleDrawPile.map(game, [], %{})

      assert Game.draw_pile(new_game) == [c1]
    end
  end
end
