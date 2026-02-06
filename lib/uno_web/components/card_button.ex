# lib/uno_web/components/card_button.ex
defmodule UnoWeb.Components.CardButton do
  use Phoenix.Component

  alias Uno.Card
  import UnoWeb.Components.CardFace

  def card_button(assigns) do
    assigns =
      assigns
      |> assign(:card_id, Card.id(assigns.card))
      |> assign(:outline?, String.contains?(assigns.class || "", "btn-outline"))

    ~H"""
    <button
      phx-click="play_card"
      phx-value-player={@player}
      phx-value-card_id={@card_id}
      class="p-0 bg-transparent border-0 outline-none focus:outline-none focus:ring-0 cursor-pointer"
    >
      <.card_face card={@card} outline?={@outline?} />
    </button>
    """
  end
end
