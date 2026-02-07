defmodule Uno.Rules do
  alias Funx.Predicate.Eq
  alias Uno.{Card, Hand, Game}

  use Funx.Validate
  use Funx.Eq
  use Funx.Ord
  use Funx.Predicate

  # ============================================================
  # CARD MATCHING AND EQUALITY
  # What it means for two cards to “match” in Uno
  # ============================================================

  # We are at the edge of what Dialyzer can infer here
  @dialyzer {:nowarn_function, playable_card_eq: 0}
  @spec playable_card_eq() :: Funx.Eq.eq_t()
  def playable_card_eq do
    eq do
      any do
        on Card.color_lens()
        on Card.value_lens()
      end
    end
  end

  @spec playable?(Card.t(), Card.t()) :: boolean()
  def playable?(%Card{} = hand_card, %Card{} = top_card) do
    playable_pred =
      pred do
        any do
          &any_wild_card?/1
          {Eq, value: top_card, eq: playable_card_eq()}
        end
      end

    playable_pred.(hand_card)
  end

  @spec color_match?(Card.t(), Card.t()) :: boolean()
  def color_match?(%Card{} = card, %Card{} = top_card) do
    Card.color(card) == Card.color(top_card)
  end

  @spec value_match?(Card.t(), Card.t()) :: boolean()
  def value_match?(%Card{} = card, %Card{} = top_card) do
    Card.value(card) == Card.value(top_card)
  end

  # ============================================================
  # CARD EFFECTS
  # What special cards mean in the game
  # ============================================================

  @spec skip_card?(Card.t()) :: boolean()
  def skip_card?(%Card{} = card) do
    Card.value(card) == "S"
  end

  @spec reverse_card?(Card.t()) :: boolean()
  def reverse_card?(%Card{} = card) do
    Card.value(card) == "R"
  end

  @spec draw_two_card?(Card.t()) :: boolean()
  def draw_two_card?(%Card{} = card) do
    Card.value(card) == "D"
  end

  @spec action_card?(Card.t()) :: boolean()
  def action_card?(%Card{} = card) do
    Card.value(card) in Card.actions()
  end

  @spec wild_card?(Card.t()) :: boolean()
  def wild_card?(%Card{} = card) do
    Card.value(card) == "W"
  end

  @spec wild_draw_four_card?(Card.t()) :: boolean()
  def wild_draw_four_card?(%Card{} = card) do
    Card.value(card) == "W4"
  end

  @spec any_wild_card?(Card.t()) :: boolean()
  def any_wild_card?(%Card{} = card) do
    any_wild_pred? =
      pred do
        any do
          &wild_card?/1
          &wild_draw_four_card?/1
        end
      end

    any_wild_pred?.(card)
  end

  # ============================================================
  # TURN AND TABLE CONDITIONS
  # Facts about the current game state
  # ============================================================

  @spec two_player?(Game.t()) :: boolean()
  def two_player?(%Game{} = game) do
    length(Game.hands(game)) == 2
  end

  @spec bot_turn?(Game.t(), MapSet.t()) :: boolean()
  def bot_turn?(%Game{} = game, bots) do
    MapSet.member?(bots, Game.current_player(game))
  end

  @spec must_say_uno?(Hand.t()) :: boolean()
  def must_say_uno?(hand) when is_list(hand), do: length(hand) == 1

  @spec discard_pile_has_cards?(Game.t()) :: boolean()
  def discard_pile_has_cards?(%Game{} = game) do
    length(Game.discard_pile(game)) > 1
  end

  # ============================================================
  # ORDERING OF PLAYS
  # How to rank cards when multiple plays are possible
  # ============================================================

  @spec play_ord(Card.t()) :: Funx.Ord.ord_t()
  def play_ord(%Card{} = top_card) do
    ord do
      desc fn card ->
        cond do
          action_card?(card) and color_match?(card, top_card) -> 4
          color_match?(card, top_card) -> 3
          value_match?(card, top_card) -> 2
          any_wild_card?(card) -> 1
          true -> 0
        end
      end
    end
  end

  # ============================================================
  # END OF GAME RULES
  # When the game ends and who wins
  # ============================================================

  @spec playable_ids(Hand.t(), Card.t()) :: MapSet.t()
  def playable_ids(hand, top_card) do
    hand
    |> Enum.filter(&playable?(&1, top_card))
    |> MapSet.new(& &1.id)
  end

  @spec game_over?(Game.t()) :: boolean()
  def game_over?(%Game{} = game) do
    hands = Game.hands(game)
    Enum.any?(hands, &Enum.empty?/1)
  end

  @spec winner(Game.t()) :: non_neg_integer() | nil
  def winner(%Game{} = game) do
    hands = Game.hands(game)
    Enum.find_index(hands, &Enum.empty?/1)
  end
end
