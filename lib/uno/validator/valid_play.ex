defmodule Uno.Validator.ValidPlay do
  @behaviour Funx.Validate.Behaviour

  alias Funx.Errors.ValidationError
  alias Funx.Monad.Either
  alias Uno.{Game, Rules}

  @impl Funx.Validate.Behaviour
  def validate(game, opts, _env) do
    player_index = Keyword.fetch!(opts, :player_index)
    card_id = Keyword.fetch!(opts, :card_id)

    top_card = Game.get_card_in_play(game)
    card = Game.get_card_in_hand(game, player_index, card_id)

    Either.lift_predicate(
      game,
      fn _ -> Rules.playable?(card, top_card) end,
      fn _ -> ValidationError.new("card must match by color or value") end
    )
  end
end
