defmodule Uno.Action.ApplyWildDrawFour do
  @behaviour Funx.Monad.Behaviour.Map

  alias Uno.{Game, Rules}
  use Funx.Monad.Maybe

  @impl Funx.Monad.Behaviour.Map
  def map(game, _opts, _env) do
    top_card = Game.get_card_in_play(game)

    if Rules.wild_draw_four_card?(top_card) do
      next_player = Game.get_next_player_index(game)

      maybe game, as: :raise do
        bind Game.draw_for_player(next_player)
        bind Game.draw_for_player(next_player)
        bind Game.draw_for_player(next_player)
        bind Game.draw_for_player(next_player)
        map Game.next_player()
      end
    else
      game
    end
  end
end
