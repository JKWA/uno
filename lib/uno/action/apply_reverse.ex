defmodule Uno.Action.ApplyReverse do
  @behaviour Funx.Monad.Behaviour.Map

  alias Uno.{Game, Rules}

  @impl Funx.Monad.Behaviour.Map
  def map(%Game{} = game, _opts, _env) do
    top_card = Game.card_in_play(game)

    cond do
      not Rules.reverse_card?(top_card) ->
        game

      Rules.two_player?(game) ->
        Game.next_player(game)

      true ->
        Game.reverse_direction(game)
    end
  end
end
