defmodule Uno.Action.DrawCard do
  @behaviour Funx.Monad.Behaviour.Map

  alias Funx.Optics.Lens
  alias Uno.{Card, Game}

  import Funx.List, only: [tail: 1]

  @impl Funx.Monad.Behaviour.Map
  def map(%Card{} = card, opts, _env) do
    game = Keyword.fetch!(opts, :game)

    game
    |> Lens.over!(Game.draw_pile_lens(), &tail/1)
    |> add_card_to_destination(card, opts)
  end

  defp add_card_to_destination(game, card, opts) do
    case Keyword.get(opts, :destination, :hand) do
      :hand ->
        player_index = Keyword.fetch!(opts, :player_index)

        Lens.over!(game, Game.hands_lens(), fn hands ->
          List.update_at(hands, player_index, fn hand -> [card | hand] end)
        end)

      :discard ->
        Lens.over!(game, Game.discard_pile_lens(), fn pile -> [card | pile] end)
    end
  end
end
