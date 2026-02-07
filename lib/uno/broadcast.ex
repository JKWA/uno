defmodule Uno.Broadcast do
  @behaviour Funx.Monad.Behaviour.Bind

  @impl true
  def bind(%Uno.Game{} = game, _opts, _env) do
    Phoenix.PubSub.broadcast(Uno.PubSub, "game:#{game.id}", {:game_updated, game})
    {:ok, game}
  end
end
