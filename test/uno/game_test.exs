defmodule Uno.GameTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Funx.Monad.Either.Right
  alias Funx.Monad.Maybe
  alias Funx.Monad.Maybe.Just
  alias Uno.Card
  alias Uno.Game

  # ------------------------------------------------------------------
  # Test helpers
  # ------------------------------------------------------------------

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

  defp card(color, value), do: Card.new(color, value)
  defp game_with_hands(hands), do: game(hands: hands)

  # ------------------------------------------------------------------

  describe "start/0" do
    test "creates a valid initial game" do
      game = Game.start()

      assert is_integer(game.id)
      assert is_list(game.draw_pile)
      assert game.discard_pile == []
      assert game.hands == []
      assert game.current_player == 0
      assert game.direction == 1
      assert game.draw_pile != []
    end
  end

  describe "build_deck/0" do
    test "produces a non-empty shuffled deck" do
      deck = Game.build_deck()

      assert is_list(deck)
      assert deck != []
      assert Enum.all?(deck, &match?(%Card{}, &1))
    end
  end

  describe "flip_card/1" do
    test "moves top card from draw pile to discard pile" do
      c1 = card(:red, "1")
      c2 = card(:blue, "2")

      game =
        game(
          draw_pile: [c1, c2],
          discard_pile: []
        )

      result = Game.flip_card(game)

      assert %Just{value: new_game} = result

      assert Game.get_draw_pile(new_game) == [c2]
      assert Game.get_discard_pile(new_game) == [c1]
    end

    test "returns Nothing when draw pile is empty" do
      game = game(draw_pile: [])

      assert Maybe.nothing?(Game.flip_card(game))
    end
  end

  describe "draw/1 and draw_for_player/2" do
    test "draw/1 delegates to draw_for_player/2" do
      c1 = card(:red, "1")

      game =
        game_with_hands([[]])
        |> Map.put(:draw_pile, [c1])
        |> Map.put(:current_player, 0)

      assert Game.draw(game) == Game.draw_for_player(game, 0)
    end

    test "draw_for_player puts card in correct hand" do
      c1 = card(:red, "1")

      game =
        game_with_hands([[], []])
        |> Map.put(:draw_pile, [c1])

      result = Game.draw_for_player(game, 1)

      assert %Right{right: new_game} = result
      assert Game.get_draw_pile(new_game) == []
      assert Game.get_hands(new_game) == [[], [c1]]
    end

    test "draw_for_player returns Left when deck empty" do
      game =
        game_with_hands([[]])
        |> Map.put(:draw_pile, [])

      assert Either.left?(Game.draw_for_player(game, 0))
    end
  end

  describe "next_player/1 and reverse_direction/1" do
    test "next_player wraps around" do
      game =
        game_with_hands([[], [], []])
        |> Map.put(:current_player, 2)
        |> Map.put(:direction, 1)

      new_game = Game.next_player(game)

      assert Game.get_current_player(new_game) == 0
    end

    test "reverse_direction flip_cards direction" do
      game =
        game()
        |> Map.put(:direction, 1)

      new_game = Game.reverse_direction(game)

      assert Game.get_direction(new_game) == -1
    end
  end

  describe "deal/3" do
    test "deals correct number of cards" do
      game = Game.start()

      %Right{right: result} = Game.deal(game, 2, 3)

      hands = Game.get_hands(result)

      assert length(hands) == 2
      assert length(Enum.at(hands, 0)) == 3
      assert length(Enum.at(hands, 1)) == 3
    end
  end

  describe "play_card/3" do
    test "removes card from hand and adds to discard pile" do
      c1 = card(:red, "1")

      game =
        game_with_hands([[c1]])
        |> Map.put(:discard_pile, [])

      new_game = Game.play_card(game, 0, Card.get_id(c1))

      assert Game.get_hands(new_game) == [[]]
      assert Game.get_discard_pile(new_game) == [c1]
    end
  end

  describe "set_wild_color/2" do
    test "changes color of top discard card" do
      c1 = card(:blue, "W")

      game =
        game()
        |> Map.put(:discard_pile, [c1])

      new_game = Game.set_wild_color(game, :red)

      new_top = Game.get_card_in_play(new_game)
      assert Card.get_color(new_top) == :red
    end
  end

  describe "reshuffle/1" do
    test "moves all but top discard card into shuffled draw pile" do
      top = card(:red, "1")
      rest = [card(:blue, "2"), card(:green, "3")]

      game =
        game()
        |> Map.put(:draw_pile, [])
        |> Map.put(:discard_pile, [top | rest])

      result = Game.reshuffle(game)

      assert %Right{right: new_game} = result

      assert Game.get_discard_pile(new_game) == [top]
      assert length(Game.get_draw_pile(new_game)) == 2
    end

    test "fails when there is only one card in discard pile" do
      game =
        game()
        |> Map.put(:discard_pile, [card(:red, "1")])

      assert Either.left?(Game.reshuffle(game))
    end
  end

  describe "get_card_in_play/1" do
    test "returns top of discard pile" do
      c1 = card(:red, "1")

      game =
        game()
        |> Map.put(:discard_pile, [c1])

      assert Game.get_card_in_play(game) == c1
    end
  end

  describe "get_hand/2" do
    test "returns the hand for the given player" do
      hand_0 = [card(:red, "1")]
      hand_1 = [card(:blue, "2")]

      game = game_with_hands([hand_0, hand_1])

      assert Game.get_hand(game, 0) == hand_0
      assert Game.get_hand(game, 1) == hand_1
    end

    test "raises when player has no hand" do
      game = game_with_hands([])

      assert_raise RuntimeError, fn ->
        Game.get_hand(game, 0)
      end
    end

    test "returns cards sorted by color then value" do
      unsorted = [
        card(:red, "5"),
        card(:blue, "3"),
        card(:red, "2"),
        card(:blue, "1")
      ]

      game = game_with_hands([unsorted])

      sorted = Game.get_hand(game, 0)

      assert Enum.map(sorted, &{Card.get_color(&1), Card.get_value(&1)}) == [
               {:blue, "1"},
               {:blue, "3"},
               {:red, "2"},
               {:red, "5"}
             ]
    end
  end
end
