defmodule Uno.Validator.GameOver do
  @behaviour Funx.Validate.Behaviour

  alias Funx.Errors.ValidationError
  alias Funx.Monad.Either
  alias Uno.Rules

  @impl Funx.Validate.Behaviour
  def validate(game, _opts, _env) do
    Either.lift_predicate(
      game,
      fn g -> Rules.game_over?(g) end,
      fn _ -> ValidationError.new("game is not over") end
    )
  end
end
