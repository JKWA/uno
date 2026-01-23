defmodule Uno.Card do
  import Funx.Macros, only: [eq_for: 2, ord_for: 2]

  alias Funx.{Eq, Ord}
  alias Funx.Monad.Either
  alias Funx.Optics.Lens
  alias Funx.Validator.In

  use Funx.Eq
  use Funx.Ord
  use Funx.Validate

  @type t :: %__MODULE__{
          id: String.t(),
          color: atom(),
          value: String.t()
        }

  # ============================================================
  # DATA AND CONSTRUCTION
  # The shape of a card and valid values
  # ============================================================

  @card_colors [:red, :blue, :green, :yellow]
  @number_cards 0..9 |> Enum.map(&Integer.to_string/1)
  @action_cards ["S", "R", "D"]
  @wild_cards ["W", "W4"]
  @card_values @number_cards ++ @action_cards ++ @wild_cards

  defstruct [:id, :color, :value]

  @spec colors() :: [atom()]
  def colors, do: @card_colors

  @spec values() :: [String.t()]
  def values, do: @card_values

  @spec actions() :: [String.t()]
  def actions, do: @action_cards

  @spec wilds() :: [String.t()]
  def wilds, do: @wild_cards

  # Invariant: when creating a new card,
  # the card must have a valid color and value.
  @spec new(atom(), String.t()) :: t()
  def new(color, value) do
    %__MODULE__{
      id: :erlang.unique_integer([:positive]) |> Integer.to_string(),
      color: color,
      value: value
    }
    |> Either.validate(validate_card())
    |> Either.to_try!()
  end

  # ============================================================
  # OPTICS AND ACCESSORS
  # Lenses and safe getters
  # ============================================================

  @spec id_lens() :: Lens.t()
  def id_lens do
    Lens.key(:id)
  end

  @spec color_lens() :: Lens.t()
  def color_lens do
    Lens.key(:color)
  end

  @spec value_lens() :: Lens.t()
  def value_lens do
    Lens.key(:value)
  end

  @spec get_id(t()) :: String.t()
  def get_id(%__MODULE__{} = card) do
    Lens.view!(card, id_lens())
  end

  @spec get_color(t()) :: atom()
  def get_color(%__MODULE__{} = card) do
    Lens.view!(card, color_lens())
  end

  @spec get_value(t()) :: String.t()
  def get_value(%__MODULE__{} = card) do
    Lens.view!(card, value_lens())
  end

  # ============================================================
  # VALIDATION
  # Ensuring a card is well-formed
  # ============================================================

  @spec validate_card() :: Funx.Validate.t()
  def validate_card do
    validate do
      at color_lens(), {In, values: @card_colors, message: fn _color -> "Invalid color" end}
      at value_lens(), {In, values: @card_values, message: fn _value -> "Invalid value" end}
    end
  end

  # ============================================================
  # EQUALITY
  # Ways to compare cards
  # ============================================================

  @spec color_eq() :: Eq.eq_t()
  def color_eq do
    eq do
      on Lens.key(:color)
    end
  end

  @spec value_eq() :: Eq.eq_t()
  def value_eq do
    eq do
      on Lens.key(:value)
    end
  end

  @spec card_eq() :: Eq.eq_t()
  def card_eq do
    eq do
      on Lens.key(:color)
      on Lens.key(:value)
    end
  end

  # Generated Eq instance for the struct
  eq_for(Uno.Card, Lens.key(:id))

  # ============================================================
  # ORDERING
  # Ways to sort cards
  # ============================================================

  @spec color_ord() :: Ord.ord_t()
  def color_ord do
    ord do
      asc Lens.key(:color)
    end
  end

  @spec value_ord() :: Ord.ord_t()
  def value_ord do
    ord do
      asc Lens.key(:value)
    end
  end

  @spec card_ord() :: Ord.ord_t()
  def card_ord do
    ord do
      asc Lens.key(:color)
      asc Lens.key(:value)
    end
  end

  ord_for(
    Uno.Card,
    ord do
      asc Lens.key(:color)
      asc Lens.key(:value)
    end
  )
end
