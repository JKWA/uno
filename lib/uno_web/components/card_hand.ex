# lib/uno_web/components/card_hand.ex
defmodule UnoWeb.Components.CardHand do
  use Phoenix.Component

  import UnoWeb.Components.CardButton

  def card_hand(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <%= for card <- @hand do %>
        <.card_button
          card={card}
          player={@player}
          class={
            if MapSet.member?(@playable_ids, card.id),
              do: "btn btn-lg",
              else: "btn btn-lg btn-outline"
          }
        />
      <% end %>
    </div>
    """
  end
end
