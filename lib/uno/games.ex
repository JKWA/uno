defmodule Uno.Games do
  use Funx.Monad.Either
  use Funx.Monad.Maybe
  alias Uno.Game
  alias Uno.Repo
  alias Funx.Monad.Either

  def create do
    new_game = Game.start()
    maybe new_game, as: :raise do
      map Game.deal(2, 7)
      bind Game.flip
      bind Repo.save
    end
  end

  def get(id) do
    Repo.get(id)
  end

  def draw_card(game_id, player_index) do
    either game_id, as: :tuple do
      bind Repo.get
      bind fn game ->
        Game.draw_for_player(game, player_index)
        |> Either.lift_maybe(:draw_pile_empty)
      end
      bind Repo.save
    end
  end

  def play_card(game_id, player_index, card_index) do
    either game_id, as: :tuple do
      bind Repo.get
      map Game.play_card(player_index, card_index)
      bind Repo.save
    end
  end
end
