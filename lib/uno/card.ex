defmodule Uno.Card do
  import Funx.Macros, only: [eq_for: 2, ord_for: 2]
  alias Funx.Optics.{Lens, Traversal}
  alias Funx.Validator.In
  use Funx.Eq
  use Funx.Ord
  use Funx.Validate

  # ============================================================
  # DATA AND CONSTRUCTION
  # The shape of a card and valid values
  # ============================================================

  @colors [:red, :blue, :green, :yellow]
  @number_values 0..9 |> Enum.map(&Integer.to_string/1)
  @action_values ["S", "R", "D"]
  @wild_values ["W", "W4"]
  @values @number_values ++ @action_values ++ @wild_values

  defstruct [:id, :color, :value]

  def colors, do: @colors
  def values, do: @values

  def new(color, value) when color in @colors and value in @values do
    %__MODULE__{
      id: :erlang.unique_integer([:positive]) |> Integer.to_string(),
      color: color,
      value: value
    }
  end

  # ============================================================
  # OPTICS AND ACCESSORS
  # Lenses and safe getters
  # ============================================================

  def id_lens do
    Lens.key(:id)
  end

  def color_lens do
    Lens.key(:color)
  end

  def value_lens do
    Lens.key(:value)
  end

  def get_id(%__MODULE__{} = card) do
    Lens.view!(card, id_lens())
  end

  def get_color(%__MODULE__{} = card) do
    Lens.view!(card, color_lens())
  end

  def get_value(%__MODULE__{} = card) do
    Lens.view!(card, value_lens())
  end

  # ============================================================
  # VALIDATION
  # Ensuring a card is well-formed
  # ============================================================

  def validate_card do
    validate do
      at value_lens(), {In, values: @values, message: fn _value -> "Invalid value" end}
      at color_lens(), {In, values: @colors, message: fn _color -> "Invalid color" end}
    end
  end

  # ============================================================
  # EQUALITY
  # Ways to compare cards
  # ============================================================

  def color_eq do
    eq do
      on Lens.key(:color)
    end
  end

  def value_eq do
    eq do
      on Lens.key(:value)
    end
  end

  def card_eq do
    eq do
      on Lens.key(:color)
      on Lens.key(:value)
    end
  end

  # Generated Eq instance for the struct
  eq_for(Uno.Card, Traversal.combine([Lens.key(:color), Lens.key(:value)]))

  # ============================================================
  # ORDERING
  # Ways to sort cards
  # ============================================================

  def color_ord do
    ord do
      asc Lens.key(:color)
    end
  end

  def value_ord do
    ord do
      asc Lens.key(:value)
    end
  end

  def card_ord do
    ord do
      asc Lens.key(:color)
      asc Lens.key(:value)
    end
  end

  ord_for(Uno.Card, Lens.path([:value]))
end
