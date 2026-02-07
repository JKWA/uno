# lib/uno_web/components/player_panel.ex
defmodule UnoWeb.Components.PlayerPanel do
  use Phoenix.Component

  import UnoWeb.Components.CardHand

  def player_panel(assigns) do
    ~H"""
    <div class={"card shadow-xl mb-6 " <> panel_classes(@current_player, @player)}>
      <div class="card-body gap-6">
        <div class="flex items-center justify-between border-b pb-3">
          <div class="flex items-center gap-3">
            <h2 class="card-title">
              Player {@player + 1}
            </h2>

            <%= if @current_player == @player do %>
              <span class="text-sm opacity-70">your turn</span>
            <% end %>
          </div>

          <div class="flex items-center gap-3">
            <%= if @uno? do %>
              <div class="badge badge-accent badge-lg">UNO!</div>
            <% end %>

            <label class="label cursor-pointer gap-2">
              <span class="label-text text-sm">auto</span>
              <input
                type="checkbox"
                class="toggle toggle-sm toggle-primary"
                checked={@bot?}
                phx-click="toggle_bot"
                phx-value-player={@player}
              />
            </label>
          </div>
        </div>

        <div class="bg-base-100/50 rounded-lg p-3">
          <.card_hand
            player={@player}
            hand={@hand}
            playable_ids={@playable_ids}
          />
        </div>

        <div class="card-actions">
          <button
            phx-click="draw_card"
            phx-value-player={@player}
            class={
              if @current_player == @player do
                "btn btn-primary btn-lg w-full"
              else
                "btn btn-neutral btn-lg w-full"
              end
            }
          >
            Draw Card
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp panel_classes(current_player, player) do
    if current_player == player do
      "bg-base-300 ring-2 ring-primary"
    else
      "bg-base-200"
    end
  end
end
