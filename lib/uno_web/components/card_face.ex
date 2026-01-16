# lib/uno_web/components/card_face.ex
defmodule UnoWeb.Components.CardFace do
  use Phoenix.Component

  import UnoWeb.CoreComponents

  attr :card, :map, required: true
  attr :outline?, :boolean, default: false
  attr :on_discard?, :boolean, default: false

  def card_face(assigns) do
    ~H"""
    <div class={"w-24 h-32 rounded-xl shadow-lg border-2 " <> card_color_class(@card, @outline?, @on_discard?)}>
      <div class="h-full w-full flex flex-col justify-between px-0.5 py-1">
        <div class="text-left text-2xl font-bold leading-none ml-0.5">
          {@card.value}
        </div>

        <div class="flex-1 flex items-center justify-center">
          <.icon name="hero-star-solid" class="w-8 h-8 opacity-100" />
        </div>

        <div class="text-right text-2xl font-bold leading-none mr-0.5">
          {@card.value}
        </div>
      </div>
    </div>
    """
  end

  # Wild cards in hand (black)
  defp card_color_class(%{value: value}, _outline?, false) when value in ["W", "W4"],
    do: "bg-gray-800 text-white border-gray-900"

  # Solid (playable / on discard)
  defp card_color_class(%{color: :red}, false, _on_discard?),
    do: "bg-red-600 text-white border-red-700"

  defp card_color_class(%{color: :blue}, false, _on_discard?),
    do: "bg-blue-600 text-white border-blue-700"

  defp card_color_class(%{color: :green}, false, _on_discard?),
    do: "bg-green-600 text-white border-green-700"

  defp card_color_class(%{color: :yellow}, false, _on_discard?),
    do: "bg-yellow-400 text-black border-yellow-500"

  # Outline (not playable)
  defp card_color_class(%{color: :red}, true, _on_discard?),
    do: "bg-transparent text-red-600 border-red-600"

  defp card_color_class(%{color: :blue}, true, _on_discard?),
    do: "bg-transparent text-blue-600 border-blue-600"

  defp card_color_class(%{color: :green}, true, _on_discard?),
    do: "bg-transparent text-green-600 border-green-600"

  defp card_color_class(%{color: :yellow}, true, _on_discard?),
    do: "bg-transparent text-yellow-600 border-yellow-600"
end
