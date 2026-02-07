defmodule Uno.Service do
  use Funx.Monad.Either
  use Funx.Monad.Maybe

  alias Funx.Validator.Not

  alias Uno.{Broadcast, Game, Repo}

  alias Uno.Action.{
    ApplyDrawTwo,
    ApplyReverse,
    ApplySkip,
    ApplyWild,
    ApplyWildDrawFour,
    DrawForPlayer
  }

  alias Uno.Validator.{CurrentTurn, GameOver, ValidPlay}
  alias Funx.Monad.Either

  # ============================================================
  # GAME LIFECYCLE
  # Creating and retrieving games
  # ============================================================

  # Invariant: when creating a new game, it must be properly initialized and saved.
  @spec create() :: Game.t()
  def create do
    new_game = Game.start()

    maybe new_game, as: :raise do
      bind Game.deal(2, 7)
      bind Game.flip_card()
      bind Repo.save()
      tap Broadcast
    end
  end

  @spec get(term()) :: {:ok, Game.t()} | {:error, any()}
  def get(id) do
    Repo.get(id) |> Either.to_result()
  end

  # ============================================================
  # PLAYER ACTIONS
  # Commands that change game state
  # ============================================================

  @spec draw_card(term(), non_neg_integer()) :: {:ok, Game.t()} | {:error, any()}
  def draw_card(game_id, player_index) do
    either game_id, as: :tuple do
      bind Repo.get()

      validate [
        {Not, validator: GameOver, message: fn -> "cannot draw a card, game is over" end},
        {CurrentTurn, player_index: player_index}
      ]

      bind {DrawForPlayer, player_index: player_index}
      bind Repo.save()
      tap Broadcast
    end
  end

  @spec play_card(term(), non_neg_integer(), String.t(), atom() | nil) ::
          {:ok, Game.t()} | {:error, any()}
  def play_card(game_id, player_index, card_id, color \\ nil) do
    either game_id, as: :tuple do
      bind Repo.get()

      validate [
        {Not, validator: GameOver, message: fn -> "cannot play a card, game is over" end},
        {CurrentTurn, player_index: player_index},
        {ValidPlay, player_index: player_index, card_id: card_id}
      ]

      map Game.play_card(player_index, card_id)
      bind {ApplyWild, color: color}
      bind {ApplyWildDrawFour, color: color}
      map ApplyReverse
      map ApplySkip
      map ApplyDrawTwo
      map Game.next_player()
      bind Repo.save()
      tap Broadcast
    end
  end
end
