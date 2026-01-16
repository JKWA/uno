defmodule Uno.Validator.GameOver do
  @behaviour Funx.Validate.Behaviour

  alias Uno.Rules
  alias Funx.Monad.Either
  alias Funx.Errors.ValidationError

  @impl Funx.Validate.Behaviour
  def validate(game, _opts, _env) do
    Either.lift_predicate(
      game,
      fn g -> Rules.game_over?(g) end,
      fn _ -> ValidationError.new("game is not over") end
    )
  end
end
