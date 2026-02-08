defmodule UnoWeb.Game.Lobby do
  use UnoWeb, :live_view

  alias Uno.GameServer

  def mount(_params, _session, socket) do
    {:ok, game} = GameServer.start_game()
    {:ok, push_navigate(socket, to: ~p"/game/#{game.id}")}
  end

  def render(assigns) do
    ~H"""
    <div>Creating game...</div>
    """
  end
end
