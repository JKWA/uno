defmodule Uno.Validator.CurrentTurn do
  @behaviour Funx.Validate.Behaviour

  alias Funx.Errors.ValidationError
  alias Funx.Monad.Either
  alias Funx.Optics.Lens
  alias Uno.Game

  @impl Funx.Validate.Behaviour
  def validate(game, opts, _env) do
    player_index = Keyword.fetch!(opts, :player_index)
    current_player = Lens.view!(game, Game.current_player_lens())

    Either.lift_predicate(
      game,
      fn _ -> player_index == current_player end,
      fn _ -> ValidationError.new("not your turn") end
    )
  end
end
