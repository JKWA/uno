defmodule Uno.Action.ApplySkip do
  @behaviour Funx.Monad.Behaviour.Map

  alias Uno.{Game, Rules}

  @impl Funx.Monad.Behaviour.Map
  def map(%Game{} = game, _opts, _env) do
    top_card = Game.card_in_play(game)

    if Rules.skip_card?(top_card) do
      Game.next_player(game)
    else
      game
    end
  end
end
