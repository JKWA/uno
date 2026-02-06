defmodule Uno.Hand do
  alias Funx.Monad.Maybe
  alias Uno.{Card, Rules}
  alias Funx.Validator.Each

  use Funx.Validate

  @type t :: [Card.t()]

  # ============================================================
  # BASIC ACCESS AND STRUCTURE
  # Getting, adding, removing cards
  # ============================================================

  # Invariant: card must exist in the hand
  @spec card(t(), String.t()) :: Card.t()
  def card(hand, card_id) when is_list(hand) do
    Enum.find(hand, &(Card.id(&1) == card_id))
    |> Maybe.from_nil()
    |> Maybe.to_try!("invalid game state: card #{card_id} not in player's hand")
  end

  # Idempotent: removing a card that is not in the hand has no effect
  @spec remove_card(t(), String.t()) :: t()
  def remove_card(hand, card_id) when is_list(hand) do
    Enum.reject(hand, &(Card.id(&1) == card_id))
  end

  # Idempotent: adding a card that is already in the hand has no effect
  @spec add_card(t(), Card.t()) :: t()
  def add_card(hand, %Card{} = card) do
    Funx.List.uniq([card | hand])
  end

  @spec sort(t()) :: t()
  def sort(hand) do
    Funx.List.sort(hand, Card.card_ord())
  end

  # ============================================================
  # HAND-SPECIFIC QUESTIONS
  # Properties of a hand in isolation
  # ============================================================

  @spec empty?(t()) :: boolean()
  def empty?(hand) when is_list(hand), do: hand == []

  @spec validate_hand() :: Funx.Validate.t()
  def validate_hand() do
    validate do
      {Each, validator: Card.validate_card()}
    end
  end

  # ============================================================
  # OPERATIONS THAT RESHAPE A HAND
  # Sorting and splitting based on playability
  # ============================================================

  @spec sort_by_playability(t(), Card.t()) :: t()
  def sort_by_playability(hand, %Card{} = top_card) when is_list(hand) do
    Funx.List.sort(hand, Rules.play_ord(top_card))
  end

  @spec split_playable(t(), Card.t()) :: {t(), t()}
  def split_playable(hand, %Card{} = top_card) when is_list(hand) do
    {playable, not_playable} =
      Enum.split_with(hand, &Rules.playable?(&1, top_card))

    {
      Funx.List.sort(playable, Rules.play_ord(top_card)),
      Funx.List.sort(not_playable, Card.card_ord())
    }
  end
end
