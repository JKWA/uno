defmodule Uno.Validator.GameOverTest do
  use ExUnit.Case, async: true

  alias Funx.Monad.Either
  alias Uno.{Card, Game}
  alias Uno.Validator.GameOver

  defp card(color, value), do: Card.new(color, value)

  defp game(hands) do
    %Game{
      id: 1,
      draw_pile: [],
      discard_pile: [card(:red, "5")],
      hands: hands,
      current_player: 0,
      direction: 1
    }
  end

  describe "validate/3" do
    test "returns Right when game is over (a player has empty hand)" do
      g = game([[], [card(:blue, "2")]])

      result = GameOver.validate(g, [], %{})

      assert Either.right?(result)
    end

    test "returns Left when game is not over (all players have cards)" do
      g = game([[card(:red, "1")], [card(:blue, "2")]])

      result = GameOver.validate(g, [], %{})

      assert Either.left?(result)
    end

    test "error message indicates game is not over" do
      g = game([[card(:red, "1")], [card(:blue, "2")]])

      result = GameOver.validate(g, [], %{})

      assert %Funx.Monad.Either.Left{left: error} = result
      assert error.errors == ["game is not over"]
    end
  end
end
