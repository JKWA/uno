defmodule Uno.GameServer do
  use GenServer
  use Funx.Monad.Either

  alias Funx.Validator.Not
  alias Uno.{Bot, Repo, Rules, Service}
  alias Uno.Validator.{BotTurn, GameOver}

  # ============================================================
  # CLIENT API
  # ============================================================

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def start_game do
    game = Service.create()
    {:ok, _pid} = DynamicSupervisor.start_child(Uno.GameSupervisor, {__MODULE__, game.id})
    {:ok, game}
  end

  def ensure_started(game_id) do
    case Registry.lookup(Uno.GameRegistry, game_id) do
      [{_pid, _}] ->
        :ok

      [] ->
        case Service.get(game_id) do
          {:ok, _game} ->
            case DynamicSupervisor.start_child(Uno.GameSupervisor, {__MODULE__, game_id}) do
              {:ok, _pid} -> :ok
              {:error, {:already_started, _pid}} -> :ok
            end

          {:error, _} ->
            {:error, :not_found}
        end
    end
  end

  def state(game_id) do
    GenServer.call(via(game_id), :state)
  end

  def play_card(game_id, player_index, card_id, color \\ nil) do
    GenServer.call(via(game_id), {:play_card, player_index, card_id, color})
  end

  def draw_card(game_id, player_index) do
    GenServer.call(via(game_id), {:draw_card, player_index})
  end

  def bots(game_id) do
    GenServer.call(via(game_id), :bots)
  end

  def redeal(game_id) do
    GenServer.call(via(game_id), :redeal)
  end

  def toggle_bot(game_id, player_index) do
    GenServer.call(via(game_id), {:toggle_bot, player_index})
  end

  defp via(game_id) do
    {:via, Registry, {Uno.GameRegistry, game_id}}
  end

  # ============================================================
  # SERVER CALLBACKS
  # ============================================================

  @impl true
  def init(game_id) do
    {:ok, game} = Service.get(game_id)
    state = %{game_id: game_id, bots: MapSet.new([1])}
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

  def handle_call(:redeal, _from, state) do
    game = Service.redeal(state.game_id)
    # state = %{state | bots: MapSet.new([1])}
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

    Phoenix.PubSub.broadcast(Uno.PubSub, "game:#{state.game_id}", {:bots_updated, bots})
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
