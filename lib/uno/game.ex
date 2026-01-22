defmodule Uno.Game do
  alias Funx.Monad.Either
  alias Funx.Monad.Maybe
  alias Funx.Optics.Lens
  alias Funx.Validator.{Each, In}
  alias Funx.Validator.Integer, as: IntegerValidator

  alias Uno.Action.DrawCard
  alias Uno.Action.RecycleDiscardPile
  alias Uno.Action.ShuffleDrawPile
  alias Uno.{Card, Hand}
  alias Uno.Validator.DiscardPileHasCards

  use Funx.Monad.Maybe
  use Funx.Monad.Either
  use Funx.Validate

  import Funx.List, only: [head: 1, head!: 1]

  @type t :: %__MODULE__{
          id: integer(),
          draw_pile: list(Card.t()),
          discard_pile: list(Card.t()),
          hands: list(Hand.t()),
          current_player: integer(),
          direction: integer()
        }

  defstruct [:id, :draw_pile, :discard_pile, :hands, :current_player, direction: 1]

  # ============================================================
  # LENSES AND BASIC ACCESSORS
  # ============================================================

  @spec id_lens() :: Lens.t()
  def id_lens, do: Lens.key(:id)

  @spec draw_pile_lens() :: Lens.t()
  def draw_pile_lens, do: Lens.key(:draw_pile)

  @spec discard_pile_lens() :: Lens.t()
  def discard_pile_lens, do: Lens.key(:discard_pile)

  @spec hands_lens() :: Lens.t()
  def hands_lens, do: Lens.key(:hands)

  @spec current_player_lens() :: Lens.t()
  def current_player_lens, do: Lens.key(:current_player)

  @spec direction_lens() :: Lens.t()
  def direction_lens, do: Lens.key(:direction)

  @spec get_draw_pile(t()) :: list(Card.t())
  def get_draw_pile(%__MODULE__{} = game), do: Lens.view!(game, draw_pile_lens())

  @spec get_discard_pile(t()) :: list(Card.t())
  def get_discard_pile(%__MODULE__{} = game), do: Lens.view!(game, discard_pile_lens())

  @spec get_hands(t()) :: list(Hand.t())
  def get_hands(%__MODULE__{} = game), do: Lens.view!(game, hands_lens())

  @spec get_current_player(t()) :: integer()
  def get_current_player(%__MODULE__{} = game),
    do: Lens.view!(game, current_player_lens())

  @spec get_direction(t()) :: integer()
  def get_direction(%__MODULE__{} = game),
    do: Lens.view!(game, direction_lens())

  # Invariant: cannot have missing hand
  @spec get_hand(t(), integer()) :: Hand.t()
  def get_hand(%__MODULE__{} = game, player_index) do
    game
    |> get_hands()
    |> Enum.at(player_index)
    |> Maybe.from_nil()
    |> Maybe.to_try!("invalid game state: missing hand for player #{player_index}")
    |> Funx.List.sort(Card.card_ord())
  end

  # Invariant: Uno always has at least one card in the discard pile
  @spec get_card_in_play(t()) :: Card.t()
  def get_card_in_play(%__MODULE__{} = game) do
    game
    |> get_discard_pile()
    |> head!()
  end

  @spec get_card_in_hand(t(), integer(), String.t()) :: Card.t()
  def get_card_in_hand(%__MODULE__{} = game, player_index, card_id) do
    game
    |> get_hand(player_index)
    |> Hand.get_card(card_id)
  end

  @spec get_next_player_index(t()) :: integer()
  def get_next_player_index(%__MODULE__{} = game) do
    direction = get_direction(game)
    current = get_current_player(game)
    num_players = get_hands(game) |> length()

    Integer.mod(current + direction, num_players)
  end

  @spec validate_game() :: Funx.Validate.t()
  def validate_game() do
    validate do
      at id_lens(), IntegerValidator
      at current_player_lens(), IntegerValidator
      at direction_lens(), {In, values: [-1, 1]}
      at draw_pile_lens(), {Each, validator: Card.validate_card()}
      at discard_pile_lens(), {Each, validator: Card.validate_card()}
      at hands_lens(), {Each, validator: Hand.validate_hand()}
    end
  end

  # ============================================================
  # GAME INITIALIZATION
  # ============================================================

  @spec start() :: t()
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
  # ============================================================

  @spec build_deck() :: list(Card.t())
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
  # ============================================================

  @spec flip_card(t()) :: Maybe.t(t())
  def flip_card(%__MODULE__{} = game) do
    draw_pile = get_draw_pile(game)

    maybe draw_pile do
      bind head()
      map {DrawCard, game: game, destination: :discard}
    end
  end

  @spec draw(t()) :: Either.t(atom(), t())
  def draw(%__MODULE__{} = game) do
    current = get_current_player(game)
    draw_for_player(game, current)
  end

  @spec draw_for_player(t(), integer()) :: Either.t(atom(), t())
  def draw_for_player(%__MODULE__{} = game, player_index) do
    draw_pile = get_draw_pile(game)

    either draw_pile do
      bind fn d -> Either.lift_maybe(head(d), fn -> :draw_pile_empty end) end
      map {DrawCard, game: game, player_index: player_index}
    end
  end

  # ============================================================
  # TURN AND DIRECTION LOGIC
  # ============================================================

  @spec next_player(t()) :: t()
  def next_player(%__MODULE__{} = game) do
    Lens.set!(game, current_player_lens(), get_next_player_index(game))
  end

  @spec reverse_direction(t()) :: t()
  def reverse_direction(%__MODULE__{} = game) do
    Lens.over!(game, direction_lens(), &(&1 * -1))
  end

  # ============================================================
  # DEALING
  # ============================================================

  @spec deal(t(), integer(), integer()) :: Either.t(any(), t())
  def deal(%__MODULE__{} = game, num_players, cards_per_player) do
    hands = List.duplicate([], num_players)
    game = Lens.set!(game, hands_lens(), hands)

    Enum.reduce(1..(num_players * cards_per_player), game, fn _, g ->
      maybe g, as: :raise do
        bind &draw/1
        map &next_player/1
      end
    end)
    |> Either.validate(validate_game())
  end

  # ============================================================
  # PLAYING CARDS
  # ============================================================

  @spec play_card(t(), integer(), String.t()) :: t()
  def play_card(%__MODULE__{} = game, player_index, card_id) do
    card = get_card_in_hand(game, player_index, card_id)

    game
    |> Lens.over!(hands_lens(), fn hands ->
      List.update_at(hands, player_index, &Hand.remove_card(&1, card_id))
    end)
    |> Lens.over!(discard_pile_lens(), fn pile -> [card | pile] end)
  end

  @spec set_wild_color(t(), atom()) :: t()
  def set_wild_color(%__MODULE__{} = game, color) do
    Lens.over!(game, discard_pile_lens(), fn [top | rest] ->
      [Lens.set!(top, Card.color_lens(), color) | rest]
    end)
  end

  # ============================================================
  # RESHUFFLING
  # ============================================================

  @spec reshuffle(t()) :: Either.t(atom(), t())
  def reshuffle(%__MODULE__{} = game) do
    either game do
      validate DiscardPileHasCards
      map RecycleDiscardPile
      map ShuffleDrawPile
    end
  end
end
