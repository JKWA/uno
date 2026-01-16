defmodule Uno.Action.DrawForPlayer do
  @behaviour Funx.Monad.Behaviour.Bind

  alias Uno.Game
  alias Funx.Monad.Either
  use Funx.Monad.Either

  @impl Funx.Monad.Behaviour.Bind
  def bind(game, opts, _env) do
    player_index = Keyword.fetch!(opts, :player_index)

    either game do
      # happy path: try to draw
      bind fn g ->
        g
        |> Game.draw_for_player(player_index)
        |> Either.lift_maybe(fn -> :draw_pile_empty end)
      end

      # recovery path: reshuffle, then draw again
      or_else fn ->
        reshuffle_and_draw(game, player_index)
      end
    end
  end

  defp reshuffle_and_draw(game, player_index) do
    either game do
      bind &Game.reshuffle/1

      bind fn g ->
        g
        |> Game.draw_for_player(player_index)
        |> Either.lift_maybe(fn -> :draw_pile_empty end)
      end
    end
  end
end
