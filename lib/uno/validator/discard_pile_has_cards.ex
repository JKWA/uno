defmodule Uno.Validator.DiscardPileHasCards do
  @behaviour Funx.Validate.Behaviour

  alias Funx.Errors.ValidationError
  alias Funx.Monad.Either
  alias Uno.Rules

  @impl Funx.Validate.Behaviour
  def validate(game, _opts, _env) do
    Either.lift_predicate(
      game,
      &Rules.discard_pile_has_cards?/1,
      fn _ -> ValidationError.new("no cards to reshuffle") end
    )
  end
end
