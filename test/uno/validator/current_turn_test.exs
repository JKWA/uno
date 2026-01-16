defmodule Uno.Validator.CurrentTurnTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Uno.{Card, Game}
  alias Uno.Validator.CurrentTurn

  defp card(color, value), do: Card.new(color, value)

  defp game(opts) do
    defaults = %Game{
      id: 1,
      draw_pile: [],
      discard_pile: [card(:red, "5")],
      hands: [[card(:red, "1")], [card(:blue, "2")]],
      current_player: Keyword.get(opts, :current_player, 0),
      direction: 1
    }

    struct!(defaults, opts)
  end

  describe "validate/3" do
    test "returns Right when player_index matches current_player" do
      g = game(current_player: 0)

      result = CurrentTurn.validate(g, [player_index: 0], %{})

      assert Either.right?(result)
    end

    test "returns Left when player_index does not match current_player" do
      g = game(current_player: 0)

      result = CurrentTurn.validate(g, [player_index: 1], %{})

      assert Either.left?(result)
    end

    test "error message indicates not your turn" do
      g = game(current_player: 0)

      result = CurrentTurn.validate(g, [player_index: 1], %{})

      assert %Funx.Monad.Either.Left{left: error} = result
      assert error.errors == ["not your turn"]
    end
  end
end
