defmodule Uno.Action.DrawCardTest do
  use ExUnit.Case, async: true

  alias Uno.Action.DrawCard
  alias Uno.{Card, Game}

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

  defp card(color, value), do: Card.new(color, value)

  defp game(opts \\ []) do
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

  defp game_with_hands(hands), do: game(hands: hands)

  # ------------------------------------------------------------

  describe "map/3 with destination: :hand" do
    test "removes top card from draw pile and adds it to the correct hand" do
      c1 = card(:red, "1")
      c2 = card(:blue, "2")

      game =
        game_with_hands([[], []])
        |> Map.put(:draw_pile, [c1, c2])

      opts = [game: game, player_index: 1]

      new_game = DrawCard.map(c1, opts, %{})

      assert Game.get_draw_pile(new_game) == [c2]
      assert Game.get_hands(new_game) == [[], [c1]]
      assert Game.get_discard_pile(new_game) == []
    end

    test "defaults to :hand when destination is not provided" do
      c1 = card(:red, "1")
      c2 = card(:blue, "2")

      game =
        game_with_hands([[], []])
        |> Map.put(:draw_pile, [c1, c2])

      opts = [game: game, player_index: 0]

      new_game = DrawCard.map(c1, opts, %{})

      assert Game.get_draw_pile(new_game) == [c2]
      assert Game.get_hands(new_game) == [[c1], []]
    end
  end

  describe "map/3 with destination: :discard" do
    test "removes top card from draw pile and adds it to discard pile" do
      c1 = card(:red, "1")
      c2 = card(:blue, "2")

      game =
        game()
        |> Map.put(:draw_pile, [c1, c2])
        |> Map.put(:discard_pile, [])

      opts = [game: game, destination: :discard]

      new_game = DrawCard.map(c1, opts, %{})

      assert Game.get_draw_pile(new_game) == [c2]
      assert Game.get_discard_pile(new_game) == [c1]
      assert Game.get_hands(new_game) == []
    end
  end

  describe "map/3 behaviour with existing hands/piles" do
    test "prepends card to an existing hand" do
      c1 = card(:red, "1")
      existing = card(:blue, "5")

      game =
        game_with_hands([[existing]])
        |> Map.put(:draw_pile, [c1])

      opts = [game: game, player_index: 0]

      new_game = DrawCard.map(c1, opts, %{})

      assert Game.get_hands(new_game) == [[c1, existing]]
    end

    test "prepends card to an existing discard pile" do
      c1 = card(:red, "1")
      existing = card(:blue, "5")

      game =
        game()
        |> Map.put(:draw_pile, [c1])
        |> Map.put(:discard_pile, [existing])

      opts = [game: game, destination: :discard]

      new_game = DrawCard.map(c1, opts, %{})

      assert Game.get_discard_pile(new_game) == [c1, existing]
    end
  end
end
