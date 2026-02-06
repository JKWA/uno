defmodule Uno.Action.ApplyWildDrawFour do
  @behaviour Funx.Monad.Behaviour.Bind

  alias Funx.Monad.Either
  alias Funx.Validator.In
  alias Uno.{Card, Game, Rules}
  alias Uno.Action.DrawForPlayer

  use Funx.Monad.Either

  @impl Funx.Monad.Behaviour.Bind
  def bind(%Game{} = game, opts, _env) do
    top_card = Game.card_in_play(game)
    color = Keyword.fetch!(opts, :color)

    if Rules.wild_draw_four_card?(top_card) do
      either color do
        validate {In, value: color, values: Card.colors()}

        map fn c -> Game.set_wild_color(game, c) end
        map apply_draw_four()
      end
    else
      Either.right(game)
    end
  end

  defp apply_draw_four(game) do
    next_player = Game.next_player_index(game)

    either game, as: :raise do
      bind {DrawForPlayer, player_index: next_player}
      bind {DrawForPlayer, player_index: next_player}
      bind {DrawForPlayer, player_index: next_player}
      bind {DrawForPlayer, player_index: next_player}
      map Game.next_player()
    end
  end
end
