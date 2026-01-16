defmodule Uno.Action.DrawForPlayer do
  @behaviour Funx.Monad.Behaviour.Bind

  alias Uno.Game

  use Funx.Monad.Either

  @impl Funx.Monad.Behaviour.Bind
  def bind(%Game{} = game, opts, _env) do
    player_index = Keyword.fetch!(opts, :player_index)

    either game do
      # happy path
      bind Game.draw_for_player(player_index)
      # recovery path
      or_else fn ->
        reshuffle_and_draw(game, player_index)
      end
    end
  end

  defp reshuffle_and_draw(game, player_index) do
    either game do
      bind Game.reshuffle()
      bind Game.draw_for_player(player_index)
    end
  end
end
