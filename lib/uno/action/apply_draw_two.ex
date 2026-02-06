defmodule Uno.Action.ApplyDrawTwo do
  @behaviour Funx.Monad.Behaviour.Map

  use Funx.Monad.Either

  alias Uno.{Game, Rules}
  alias Uno.Action.DrawForPlayer

  @impl Funx.Monad.Behaviour.Map
  def map(%Game{} = game, _opts, _env) do
    top_card = Game.card_in_play(game)

    if Rules.draw_two_card?(top_card) do
      next_player = Game.next_player_index(game)

      either game, as: :raise do
        bind {DrawForPlayer, player_index: next_player}
        bind {DrawForPlayer, player_index: next_player}
        map Game.next_player()
      end
    else
      game
    end
  end
end
