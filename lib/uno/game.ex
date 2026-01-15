defmodule Uno.Game do
  alias Uno.Card
  alias Uno.Rules
  alias Funx.Optics.Lens
  alias Funx.Monad.Either
  use Funx.Monad.Maybe
  use Funx.Monad.Either

  defstruct [:id, :draw_pile, :discard_pile, :hands, :current_player]

  def draw_pile_lens, do: Lens.key(:draw_pile)
  def discard_pile_lens, do: Lens.key(:discard_pile)
  def hands_lens, do: Lens.key(:hands)
  def current_player_lens, do: Lens.key(:current_player)

  def start do
    %__MODULE__{
      id: :erlang.unique_integer([:positive]),
      draw_pile: deck(),
      discard_pile: [],
      hands: [],
      current_player: 0
    }
  end

  def start(%__MODULE__{} = game) do
    Lens.set!(game, draw_pile_lens(), deck())
  end

  # Standard Uno: one 0 per color, two of each 1-9 per color
  def deck do
    zeros = for color <- Card.colors(), do: Card.new(color, 0)

    others =
      for color <- Card.colors(),
          value <- 1..9,
          _copy <- 1..2 do
        Card.new(color, value)
      end

    Enum.shuffle(zeros ++ others)
  end

  def flip(%__MODULE__{} = game) do
    maybe Lens.view!(game, draw_pile_lens()) do
      bind Funx.List.head()

      map fn card ->
        game
        |> Lens.over!(draw_pile_lens(), &tl/1)
        |> Lens.over!(discard_pile_lens(), fn pile -> [card | pile] end)
      end
    end
  end

  def draw(%__MODULE__{} = game) do
    maybe Lens.view!(game, draw_pile_lens()) do
      bind Funx.List.head()

      map fn card ->
        current = Lens.view!(game, current_player_lens())

        game
        |> Lens.over!(draw_pile_lens(), &tl/1)
        |> Lens.over!(hands_lens(), fn hands ->
          List.update_at(hands, current, fn hand -> [card | hand] end)
        end)
      end
    end
  end

  def next_player(%__MODULE__{} = game) do
    hands = Lens.view!(game, hands_lens())
    Lens.over!(game, current_player_lens(), fn current -> rem(current + 1, length(hands)) end)
  end

  def deal(%__MODULE__{} = game, num_players, cards_per_player) do
    hands = List.duplicate([], num_players)
    game = Lens.set!(game, hands_lens(), hands)

    Enum.reduce(1..(num_players * cards_per_player), game, fn _, g ->
      maybe g, as: :raise do
        bind &draw/1
        map &next_player/1
      end
    end)
  end

  def draw_for_player(%__MODULE__{} = game, player_index) do
    maybe Lens.view!(game, draw_pile_lens()) do
      bind Funx.List.head()
      map fn card ->
        game
        |> Lens.over!(draw_pile_lens(), &tl/1)
        |> Lens.over!(hands_lens(), fn hands ->
          List.update_at(hands, player_index, fn hand -> [card | hand] end)
        end)
      end
    end
  end

  def play_card(%__MODULE__{} = game, player_index, card_index) do
    hands = Lens.view!(game, hands_lens())
    hand = Enum.at(hands, player_index)
    card = Enum.at(hand, card_index)

    game
    |> Lens.over!(hands_lens(), fn hands ->
      List.update_at(hands, player_index, fn hand -> List.delete_at(hand, card_index) end)
    end)
    |> Lens.over!(discard_pile_lens(), fn pile -> [card | pile] end)
  end

  def reshuffle(%__MODULE__{} = game) do
    predicate = &Rules.discard_pile_has_cards?/1

    either game do
      bind Either.lift_predicate(predicate, fn _ -> :no_cards_to_reshuffle end)

      map fn g ->
        [top | rest] = Lens.view!(g, discard_pile_lens())

        g
        |> Lens.set!(discard_pile_lens(), [top])
        |> Lens.set!(draw_pile_lens(), rest)
      end

      map fn g -> Lens.over!(g, draw_pile_lens(), &Enum.shuffle/1) end
    end
  end
end
