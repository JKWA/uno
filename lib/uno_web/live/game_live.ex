defmodule UnoWeb.GameLive do
  use UnoWeb, :live_view

  alias Uno.Games

  def mount(_params, _session, socket) do
    game = Games.create()

    {:ok, assign(socket, game: game, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @error do %>
        <p style="color: red;"><%= @error %></p>
      <% end %>

      <h2>Player 1</h2>
      <div style="display: flex; gap: 8px;">
        <%= for {card, index} <- Enum.with_index(Enum.at(@game.hands, 0) || []) do %>
          <button phx-click="play_card" phx-value-player="0" phx-value-card={index}>
            <%= card.color %> <%= card.value %>
          </button>
        <% end %>
      </div>
      <button phx-click="draw_card" phx-value-player="0">Draw Card</button>

      <hr />

      <h2>Discard Pile</h2>
      <div>
        <%= if top_card = List.first(@game.discard_pile) do %>
          <strong><%= top_card.color %> <%= top_card.value %></strong>
        <% else %>
          (empty)
        <% end %>
      </div>

      <hr />

      <h2>Player 2</h2>
      <div style="display: flex; gap: 8px;">
        <%= for {card, index} <- Enum.with_index(Enum.at(@game.hands, 1) || []) do %>
          <button phx-click="play_card" phx-value-player="1" phx-value-card={index}>
            <%= card.color %> <%= card.value %>
          </button>
        <% end %>
      </div>
      <button phx-click="draw_card" phx-value-player="1">Draw Card</button>
    </div>
    """
  end

  def handle_event("play_card", %{"player" => player, "card" => card}, socket) do
    player_index = String.to_integer(player)
    card_index = String.to_integer(card)

    case Games.play_card(socket.assigns.game.id, player_index, card_index) do
      {:ok, game} -> {:noreply, assign(socket, game: game, error: nil)}
      {:error, reason} -> {:noreply, assign(socket, error: inspect(reason))}
    end
  end

  def handle_event("draw_card", %{"player" => player}, socket) do
    player_index = String.to_integer(player)

    case Games.draw_card(socket.assigns.game.id, player_index) do
      {:ok, game} -> {:noreply, assign(socket, game: game, error: nil)}
      {:error, reason} -> {:noreply, assign(socket, error: inspect(reason))}
    end
  end
end
