defmodule Uno.Game do
  alias Uno.Card
  alias Uno.Rules
  alias Uno.Action.DrawCard
  alias Funx.Monad.Maybe
  alias Funx.Optics.Lens
  alias Funx.Monad.Either
  use Funx.Monad.Maybe
  use Funx.Monad.Either

  import Funx.List, only: [head: 1, head!: 1]

  defstruct [:id, :draw_pile, :discard_pile, :hands, :current_player, direction: 1]

  # ============================================================
  # LENSES AND BASIC ACCESSORS
  #
  # These accessors assume the internal structure of Game is
  # consistent.  Failure represents a broken invariant, not a
  # recoverable business error.
  # ============================================================

  def draw_pile_lens, do: Lens.key(:draw_pile)
  def discard_pile_lens, do: Lens.key(:discard_pile)
  def hands_lens, do: Lens.key(:hands)
  def current_player_lens, do: Lens.key(:current_player)
  def direction_lens, do: Lens.key(:direction)

  def get_draw_pile(%__MODULE__{} = game), do: Lens.view!(game, draw_pile_lens())
  def get_discard_pile(%__MODULE__{} = game), do: Lens.view!(game, discard_pile_lens())
  def get_hands(%__MODULE__{} = game), do: Lens.view!(game, hands_lens())
  def get_current_player(%__MODULE__{} = game), do: Lens.view!(game, current_player_lens())
  def get_direction(%__MODULE__{} = game), do: Lens.view!(game, direction_lens())

  # Invariant: when asked for a player's hand,
  # that hand must exist.
  def get_hand(%__MODULE__{} = game, player_index) do
    game
    |> get_hands()
    |> Enum.at(player_index)
    |> Maybe.from_nil()
    |> Maybe.to_try!("invalid game state: missing hand for player #{player_index}")
    |> Funx.List.sort(Card.card_ord())
  end

  # Invariant: In Uno, there must always be a card in play.
  def get_card_in_play(%__MODULE__{} = game) do
    game
    |> get_discard_pile()
    |> head!()
  end

  # Invariant: when asked for a card in a player's hand,
  # that card must exist.
  def get_card_in_hand(%__MODULE__{} = game, player_index, card_id) do
    game
    |> get_hands()
    |> Enum.at(player_index)
    |> Enum.find(&(Card.get_id(&1) == card_id))
    |> Maybe.from_nil()
    |> Maybe.to_try!("invalid game state: card #{card_id} not in player #{player_index} hand")
  end

  # ============================================================
  # GAME INITIALIZATION
  # Creating or resetting a game
  # ============================================================

  def start do
    %__MODULE__{
      id: :erlang.unique_integer([:positive]),
      draw_pile: build_deck(),
      discard_pile: [],
      hands: [],
      current_player: 0
    }
  end

  # ============================================================
  # DECK CONSTRUCTION
  # What cards exist in the game
  # ============================================================

  def build_deck do
    zeros = for color <- Card.colors(), do: Card.new(color, "0")

    numbers =
      for color <- Card.colors(),
          value <- 1..9,
          _copy <- 1..2 do
        Card.new(color, Integer.to_string(value))
      end

    skips =
      for color <- Card.colors(),
          _copy <- 1..2 do
        Card.new(color, "S")
      end

    reverses =
      for color <- Card.colors(),
          _copy <- 1..2 do
        Card.new(color, "R")
      end

    draw_twos =
      for color <- Card.colors(),
          _copy <- 1..2 do
        Card.new(color, "D")
      end

    wilds =
      for _copy <- 1..4 do
        Card.new(:blue, "W")
      end

    wild_draw_fours =
      for _copy <- 1..4 do
        Card.new(:blue, "W4")
      end

    Enum.shuffle(zeros ++ numbers ++ skips ++ reverses ++ draw_twos ++ wilds ++ wild_draw_fours)
  end

  # ============================================================
  # DRAW AND DISCARD OPERATIONS
  # Moving cards between piles
  # ============================================================

  def flip(%__MODULE__{} = game) do
    draw_pile = get_draw_pile(game)

    maybe draw_pile do
      bind head()
      map {DrawCard, game: game, destination: :discard}
    end
  end

  def draw(%__MODULE__{} = game) do
    current = get_current_player(game)
    draw_for_player(game, current)
  end

  def draw_for_player(%__MODULE__{} = game, player_index) do
    draw_pile = get_draw_pile(game)

    maybe draw_pile do
      bind head()
      map {DrawCard, game: game, player_index: player_index}
    end
  end

  # ============================================================
  # TURN AND DIRECTION LOGIC
  # Advancing or reversing play
  # ============================================================

  def next_player(%__MODULE__{} = game) do
    hands = get_hands(game)
    direction = get_direction(game)
    num_players = length(hands)

    Lens.over!(game, current_player_lens(), fn current ->
      Integer.mod(current + direction, num_players)
    end)
  end

  def reverse_direction(%__MODULE__{} = game) do
    Lens.over!(game, direction_lens(), &(&1 * -1))
  end

  # ============================================================
  # DEALING
  # Initial distribution of cards
  # ============================================================

  # Invariant: the deal must succeed or the state is invalid.
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

  # ============================================================
  # PLAYING CARDS
  # ============================================================

  def play_card(%__MODULE__{} = game, player_index, card_id) do
    card = get_card_in_hand(game, player_index, card_id)

    game
    |> Lens.over!(hands_lens(), fn hands ->
      List.update_at(hands, player_index, fn hand ->
        Enum.reject(hand, &(Card.get_id(&1) == card_id))
      end)
    end)
    |> Lens.over!(discard_pile_lens(), fn pile -> [card | pile] end)
  end

  def set_wild_color(%__MODULE__{} = game, color) do
    Lens.over!(game, discard_pile_lens(), fn [top | rest] ->
      [Lens.set!(top, Card.color_lens(), color) | rest]
    end)
  end

  # ============================================================
  # RESHUFFLING
  # Rebuilding draw pile from discard pile
  # ============================================================

  def reshuffle(%__MODULE__{} = game) do
    predicate = &Rules.discard_pile_has_cards?/1

    either game do
      bind Either.lift_predicate(predicate, fn _ -> :no_cards_to_reshuffle end)

      map fn g ->
        [top | rest] = get_discard_pile(g)

        g
        |> Lens.set!(discard_pile_lens(), [top])
        |> Lens.set!(draw_pile_lens(), rest)
      end

      map fn g ->
        Lens.over!(g, draw_pile_lens(), &Enum.shuffle/1)
      end
    end
  end
end
