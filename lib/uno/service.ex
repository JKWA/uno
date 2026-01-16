defmodule Uno.Service do
  use Funx.Monad.Either
  use Funx.Monad.Maybe

  alias Uno.{Game, Repo}
  alias Uno.Action.DrawForPlayer
  alias Uno.Action.AdvanceTurn
  alias Uno.Validator.{CurrentTurn, GameOver, ValidPlay}
  alias Funx.Validator.Not

  # ============================================================
  # GAME LIFECYCLE
  # Creating and retrieving games
  # ============================================================

  def create do
    new_game = Game.start()

    maybe new_game, as: :raise do
      map Game.deal(2, 7)
      bind Game.flip()
      bind Repo.save()
    end
  end

  def get(id) do
    Repo.get(id)
  end

  # ============================================================
  # PLAYER ACTIONS
  # Commands that change game state
  # ============================================================

  def draw_card(game_id, player_index) do
    either game_id, as: :tuple do
      bind Repo.get()

      validate [
        {Not, validator: GameOver, message: fn -> "cannot draw a card, game is over" end},
        {CurrentTurn, player_index: player_index}
      ]

      bind {DrawForPlayer, player_index: player_index}

      bind Repo.save()
    end
  end

  def play_card(game_id, player_index, card_id) do
    either game_id, as: :tuple do
      bind Repo.get()

      validate [
        {Not, validator: GameOver, message: fn -> "cannot play a card, game is over" end},
        {CurrentTurn, player_index: player_index},
        {ValidPlay, player_index: player_index, card_id: card_id}
      ]

      map Game.play_card(player_index, card_id)
      map AdvanceTurn
      bind Repo.save()
    end
  end

  def set_wild_color(game_id, color) do
    either game_id, as: :tuple do
      bind Repo.get()
      map Game.set_wild_color(color)
      bind Repo.save()
    end
  end
end
