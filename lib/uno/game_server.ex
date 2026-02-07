defmodule Uno.GameServer do
  use GenServer

  alias Uno.{Bot, Rules, Service}

  @game_id "1"

  # ============================================================
  # CLIENT API
  # ============================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def play_card(player_index, card_id, color \\ nil) do
    GenServer.call(__MODULE__, {:play_card, player_index, card_id, color})
  end

  def draw_card(player_index) do
    GenServer.call(__MODULE__, {:draw_card, player_index})
  end

  def new_game do
    GenServer.call(__MODULE__, :new_game)
  end

  # ============================================================
  # SERVER CALLBACKS
  # ============================================================

  @impl true
  def init(:ok) do
    game =
      case Service.get(@game_id) do
        {:ok, existing} -> existing
        {:error, _} -> Service.create()
      end

    schedule_bot_if_needed(game)
    {:ok, game.id}
  end

  @impl true
  def handle_call(:state, _from, game_id) do
    {:ok, game} = Service.get(game_id)
    {:reply, game, game_id}
  end

  def handle_call({:play_card, player_index, card_id, color}, _from, game_id) do
    case Service.play_card(game_id, player_index, card_id, color) do
      {:ok, game} ->
        schedule_bot_if_needed(game)
        {:reply, {:ok, game}, game_id}

      error ->
        {:reply, error, game_id}
    end
  end

  def handle_call({:draw_card, player_index}, _from, game_id) do
    case Service.draw_card(game_id, player_index) do
      {:ok, game} ->
        schedule_bot_if_needed(game)
        {:reply, {:ok, game}, game_id}

      error ->
        {:reply, error, game_id}
    end
  end

  def handle_call(:new_game, _from, _game_id) do
    game = Service.create()
    schedule_bot_if_needed(game)
    {:reply, game, game.id}
  end

  @impl true
  def handle_info(:bot_turn, game_id) do
    with {:ok, game} <- Service.get(game_id),
         true <- game.current_player == 1 and not Rules.game_over?(game),
         {:ok, updated} <- Bot.take_turn(game, 1) do
      schedule_bot_if_needed(updated)
      {:noreply, game_id}
    else
      _ -> {:noreply, game_id}
    end
  end

  defp schedule_bot_if_needed(game) do
    if game.current_player == 1 and not Rules.game_over?(game) do
      Process.send_after(self(), :bot_turn, 1200)
    end
  end
end
