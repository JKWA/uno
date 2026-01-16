defmodule Uno.Action.ApplyWild do
  @behaviour Funx.Monad.Behaviour.Bind

  alias Funx.Monad.Either
  alias Funx.Validator.In
  alias Uno.{Card, Game, Rules}

  use Funx.Monad.Either

  @impl Funx.Monad.Behaviour.Bind
  def bind(%Game{} = game, opts, _env) do
    top_card = Game.get_card_in_play(game)
    color = Keyword.fetch!(opts, :color)

    if Rules.wild_card?(top_card) do
      either color do
        validate {In, value: color, values: Card.colors()}

        map fn c -> Game.set_wild_color(game, c) end
      end
    else
      Either.right(game)
    end
  end
end
