defmodule Uno.Action.AdvanceTurnTest do
  use ExUnit.Case, async: true

  alias Uno.{Game, Card}
  alias Uno.Action.AdvanceTurn

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

  defp game_with_hands(hands), do: game(hands: hands)

  defp with_top_card(game, card) do
    Map.put(game, :discard_pile, [card])
  end

  # ------------------------------------------------------------

  describe "map/3 default advance" do
    test "advances to next player when no special card is played" do
      top = card(:red, "5")

      game =
        game_with_hands([[], [], []])
        |> Map.put(:current_player, 0)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      assert Game.get_current_player(new_game) == 1
    end
  end

  describe "reverse rule" do
    test "reverses direction in games with more than two players" do
      top = card(:red, "R")

      game =
        game_with_hands([[], [], []])
        |> Map.put(:current_player, 0)
        |> Map.put(:direction, 1)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      assert Game.get_direction(new_game) == -1
      assert Game.get_current_player(new_game) == 2
    end

    test "acts like skip in a two-player game" do
      top = card(:red, "R")

      game =
        game_with_hands([[], []])
        |> Map.put(:current_player, 0)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      assert Game.get_current_player(new_game) == 0
    end
  end

  describe "skip rule" do
    test "skips the next player" do
      top = card(:red, "S")

      game =
        game_with_hands([[], [], []])
        |> Map.put(:current_player, 0)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      assert Game.get_current_player(new_game) == 2
    end
  end

  describe "draw two rule" do
    test "draw two forces the next player to draw two cards and lose their turn" do
      top = card(:red, "D")

      draw_pile = [
        card(:blue, "1"),
        card(:green, "2"),
        card(:yellow, "3")
      ]

      game =
        game_with_hands([
          [card(:red, "5")],
          [],
          [card(:green, "9")]
        ])
        |> Map.put(:draw_pile, draw_pile)
        |> Map.put(:current_player, 0)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      hands = Game.get_hands(new_game)

      assert length(Enum.at(hands, 1)) == 2
      assert Game.get_current_player(new_game) == 2
    end
  end

  describe "wild draw four rule" do
    test "forces next player to draw four cards and lose their turn" do
      top = card(:blue, "W4")

      draw_pile = [
        card(:red, "1"),
        card(:red, "2"),
        card(:red, "3"),
        card(:red, "4"),
        card(:red, "5")
      ]

      game =
        game_with_hands([[], [], []])
        |> Map.put(:draw_pile, draw_pile)
        |> Map.put(:current_player, 0)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      hands = Game.get_hands(new_game)

      assert length(Enum.at(hands, 1)) == 4
      assert Game.get_current_player(new_game) == 2
    end
  end

  describe "interaction of rules" do
    test "applies effects before final next_player" do
      top = card(:red, "D")

      game =
        game_with_hands([[], [], []])
        |> Map.put(:draw_pile, [
          card(:blue, "1"),
          card(:blue, "2"),
          card(:blue, "3")
        ])
        |> Map.put(:current_player, 1)
        |> with_top_card(top)

      new_game = AdvanceTurn.map(game, [], %{})

      assert Game.get_current_player(new_game) == 0
    end
  end
end
