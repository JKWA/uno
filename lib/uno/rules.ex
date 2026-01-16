defmodule Uno.Rules do
  alias Funx.List
  alias Funx.Optics.Lens
  alias Uno.{Card, Game}
  use Funx.Validate
  use Funx.Eq
  use Funx.Ord
  use Funx.Predicate

  # ============================================================
  # CARD MATCHING AND EQUALITY
  # What it means for two cards to “match” in Uno
  # ============================================================

  def playable_card_eq do
    eq do
      any do
        on Lens.key(:color)
        on Lens.key(:value)
      end
    end
  end

  def playable?(%Card{} = hand_card, %Card{} = top_card) do
    wild_card?(hand_card) or Funx.Eq.eq?(hand_card, top_card, playable_card_eq())
  end

  # ============================================================
  # CARD EFFECTS
  # What special cards mean in the game
  # ============================================================

  def skip_card?(%Card{} = card) do
    Card.get_value(card) == "S"
  end

  def reverse_card?(%Card{} = card) do
    Card.get_value(card) == "R"
  end

  def draw_two_card?(%Card{} = card) do
    Card.get_value(card) == "D"
  end

  def wild_card?(%Card{} = card) do
    Card.get_value(card) in ["W", "W4"]
  end

  def wild_draw_four_card?(%Card{} = card) do
    Card.get_value(card) == "W4"
  end

  # ============================================================
  # TURN AND TABLE CONDITIONS
  # Facts about the current game state
  # ============================================================

  def two_player?(%Game{} = game) do
    length(Lens.view!(game, Game.hands_lens())) == 2
  end

  def discard_pile_has_cards?(%Game{} = game) do
    length(Lens.view!(game, Game.discard_pile_lens())) > 1
  end

  # ============================================================
  # HAND AND PLAYABILITY OPERATIONS
  # Working with lists of cards
  # ============================================================

  def sort_by_playability(hand, top_card) do
    List.sort(hand, play_ord(top_card))
  end

  def split_hand(hand, %Card{} = top_card) do
    {playable, not_playable} =
      Enum.split_with(hand, &playable?(&1, top_card))

    {
      Funx.List.sort(playable, play_ord(top_card)),
      Funx.List.sort(not_playable, Card.card_ord())
    }
  end

  # ============================================================
  # ORDERING OF PLAYS
  # How to rank cards when multiple plays are possible
  # ============================================================

  def play_ord(%Card{} = top_card) do
    ord do
      desc fn card ->
        color_match = Card.get_color(card) == Card.get_color(top_card)
        value_match = Card.get_value(card) == Card.get_value(top_card)
        is_action = Card.get_value(card) in ["S", "R", "D"]
        is_wild = Card.get_value(card) in ["W", "W4"]

        cond do
          is_action and color_match -> 4
          color_match -> 3
          value_match -> 2
          is_wild -> 1
          true -> 0
        end
      end
    end
  end

  # ============================================================
  # END OF GAME RULES
  # When the game ends and who wins
  # ============================================================

  def must_say_uno?(hand) do
    length(hand) == 1
  end

  def game_over?(%Game{} = game) do
    hands = Game.get_hands(game)
    Enum.any?(hands, &Enum.empty?/1)
  end

  def winner(%Game{} = game) do
    hands = Game.get_hands(game)
    Enum.find_index(hands, &Enum.empty?/1)
  end
end
