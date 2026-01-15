defmodule Uno.Rules do
  alias Funx.Validator.{Any, Equal}
  alias Funx.Optics.{Lens, Prism}
  alias Uno.{Card, Game}
  use Funx.Validate
  use Funx.Eq

  # Card playability - eq comparator for matching color OR value
  def playable_card do
    eq do
      any do
        on Prism.key(:color)
        on Prism.key(:value)
      end
    end
  end

  # Game state predicates
  def discard_pile_has_cards?(%Game{} = game) do
    length(Lens.view!(game, Game.discard_pile_lens())) > 1
  end

  # Validators
  def card_color_match(%Card{} = shown) do
    validate do
      at Card.color_lens(),
         {
           Equal,
           value: Lens.view!(shown, Card.color_lens())
         }
    end
  end

  def card_value_match(%Card{} = shown) do
    validate do
      at Card.value_lens(),
         {
           Equal,
           value: Lens.view!(shown, Card.value_lens())
         }
    end
  end

  def card_match(%Card{} = shown) do
    validate do
      {
        Any,
        validators: [card_color_match(shown), card_value_match(shown)],
        message: fn -> "Cards must be playable on each other" end
      }
    end
  end
end
