defmodule Uno.Card do
  import Funx.Macros, only: [eq_for: 2, ord_for: 2]
  alias Funx.Optics.{Lens, Traversal}
  alias Funx.Validator.{Range, In}
  use Funx.Eq
  use Funx.Ord
  use Funx.Validate

  @colors [:red, :blue, :green, :yellow]
  @values 0..9 |> Enum.to_list()

  defstruct [:color, :value]

  def colors, do: @colors
  def values, do: @values

  def new(color, value) when color in @colors and value in 0..9 do
    %__MODULE__{color: color, value: value}
  end

  def color_lens do
    Lens.key(:color)
  end

  def value_lens do
    Lens.key(:value)
  end

  def validate_card do
    validate do
      at value_lens(), {Range, min: 0, max: 9, message: fn _value -> "Invalid value" end}
      at color_lens(), {In, values: @colors, message: fn _color -> "Invalid color" end}
    end
  end

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

  eq_for(Uno.Card, Traversal.combine([Lens.key(:color), Lens.key(:value)]))
  ord_for(Uno.Card, Lens.path([:color, :value]))
end
