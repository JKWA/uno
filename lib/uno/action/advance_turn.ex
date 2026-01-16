defmodule Uno.Action.AdvanceTurn do
  @behaviour Funx.Monad.Behaviour.Map

  alias Uno.{Game, Rules}
  use Funx.Monad.Maybe

  @impl Funx.Monad.Behaviour.Map
  def map(game, _opts, _env) do
    game
    |> apply_reverse_rule()
    |> apply_skip_rule()
    |> apply_draw_two_rule()
    |> apply_wild_draw_four_rule()
    |> Game.next_player()
  end

  defp apply_reverse_rule(game) do
    top_card = Game.get_card_in_play(game)

    cond do
      not Rules.reverse_card?(top_card) ->
        game

      Rules.two_player?(game) ->
        Game.next_player(game)

      true ->
        Game.reverse_direction(game)
    end
  end

  defp apply_skip_rule(game) do
    top_card = Game.get_card_in_play(game)

    if Rules.skip_card?(top_card) do
      Game.next_player(game)
    else
      game
    end
  end

  defp apply_draw_two_rule(game) do
    top_card = Game.get_card_in_play(game)

    if Rules.draw_two_card?(top_card) do
      next_player = get_next_player_index(game)

      maybe game, as: :raise do
        bind Game.draw_for_player(next_player)
        bind Game.draw_for_player(next_player)
        map Game.next_player()
      end
    else
      game
    end
  end

  defp apply_wild_draw_four_rule(game) do
    top_card = Game.get_card_in_play(game)

    if Rules.wild_draw_four_card?(top_card) do
      next_player = get_next_player_index(game)

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

  defp get_next_player_index(game) do
    hands = Game.get_hands(game)
    direction = Game.get_direction(game)
    current = Game.get_current_player(game)
    num_players = length(hands)

    Integer.mod(current + direction, num_players)
  end
end
