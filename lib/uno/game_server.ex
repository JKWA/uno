defmodule Uno.GameServer do
  use GenServer
  use Funx.Monad.Either

  alias Funx.Validator.Not
  alias Uno.{Bot, Repo, Rules, Service}
  alias Uno.Validator.{BotTurn, GameOver}

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

  def bots do
    GenServer.call(__MODULE__, :bots)
  end

  def toggle_bot(player_index) do
    GenServer.call(__MODULE__, {:toggle_bot, player_index})
  end

  # ============================================================
  # SERVER CALLBACKS
  # ============================================================

  @impl true
  def init(:ok) do
    game = Service.create()
    state = %{game_id: game.id, bots: MapSet.new([1])}
    schedule_bot_if_needed(game, state.bots)
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:ok, game} = Service.get(state.game_id)
    {:reply, game, state}
  end

  def handle_call({:play_card, player_index, card_id, color}, _from, state) do
    result =
      either state.game_id, as: :tuple do
        bind Service.play_card(player_index, card_id, color)
        tap schedule_bot_if_needed(state.bots)
      end

    {:reply, result, state}
  end

  def handle_call({:draw_card, player_index}, _from, state) do
    result =
      either state.game_id, as: :tuple do
        bind Service.draw_card(player_index)
        tap schedule_bot_if_needed(state.bots)
      end

    {:reply, result, state}
  end

  def handle_call(:new_game, _from, state) do
    game = Service.create()
    state = %{state | game_id: game.id}
    schedule_bot_if_needed(game, state.bots)
    {:reply, game, state}
  end

  def handle_call(:bots, _from, state) do
    {:reply, state.bots, state}
  end

  def handle_call({:toggle_bot, player_index}, _from, state) do
    bots = Bot.toggle(state.bots, player_index)

    state = %{state | bots: bots}

    either state.game_id do
      bind Repo.get()
      tap schedule_bot_if_needed(bots)
    end

    Phoenix.PubSub.broadcast(Uno.PubSub, "game:current", {:bots_updated, bots})
    {:reply, bots, state}
  end

  @impl true
  def handle_info(:bot_turn, state) do
    either state.game_id, as: :tuple do
      bind Repo.get()

      validate [
        {BotTurn, bots: state.bots},
        {Not, validator: GameOver, message: fn -> "game is over" end}
      ]

      bind Bot.take_turn()
      tap schedule_bot_if_needed(state.bots)
    end

    {:noreply, state}
  end

  defp schedule_bot_if_needed(game, bots) do
    if Rules.bot_turn?(game, bots) and not Rules.game_over?(game) do
      Process.send_after(self(), :bot_turn, 1200)
    end
  end
end
