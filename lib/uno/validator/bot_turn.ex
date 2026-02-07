defmodule Uno.Validator.BotTurn do
  @behaviour Funx.Validate.Behaviour

  alias Funx.Errors.ValidationError
  alias Funx.Monad.Either
  alias Uno.Rules

  @impl Funx.Validate.Behaviour
  def validate(game, opts, _env) do
    bots = Keyword.fetch!(opts, :bots)

    Either.lift_predicate(
      game,
      fn g -> Rules.bot_turn?(g, bots) end,
      fn _ -> ValidationError.new("not a bot's turn") end
    )
  end
end
