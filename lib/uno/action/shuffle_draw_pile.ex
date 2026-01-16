defmodule Uno.Action.ShuffleDrawPile do
  @behaviour Funx.Monad.Behaviour.Map

  alias Funx.Optics.Lens
  alias Uno.Game

  @impl Funx.Monad.Behaviour.Map
  def map(%Game{} = game, _opts, _env) do
    Lens.over!(game, Game.draw_pile_lens(), &Enum.shuffle/1)
  end
end
