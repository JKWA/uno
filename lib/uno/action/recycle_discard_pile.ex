defmodule Uno.Action.RecycleDiscardPile do
  @behaviour Funx.Monad.Behaviour.Map

  alias Funx.Optics.Lens
  alias Uno.Game

  @impl Funx.Monad.Behaviour.Map
  def map(%Game{} = game, _opts, _env) do
    [top | rest] = Game.discard_pile(game)

    game
    |> Lens.set!(Game.discard_pile_lens(), [top])
    |> Lens.set!(Game.draw_pile_lens(), rest)
  end
end
