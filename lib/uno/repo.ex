defmodule Uno.Repo do
  import Funx.Monad
  alias Funx.Monad.Either
  alias Uno.Game
  alias Uno.Store

  @table_name :uno

  @spec create_table() :: Either.t(any(), atom())
  def create_table do
    Store.create_table(@table_name)
  end

  @spec save(Game.t()) :: Either.t(any(), Game.t())
  def save(%Game{} = game) do
    Store.insert_item(@table_name, game)
  end

  @spec get(term()) :: Either.t(:not_found | any(), Game.t())
  def get(id) do
    Store.get_item(@table_name, id)
    |> map(fn data -> struct(Game, data) end)
  end

  @spec list() :: [Game.t()]
  def list do
    Store.get_all_items(@table_name)
    |> map(fn items -> Enum.map(items, fn item -> struct(Game, item) end) end)
    |> Either.get_or_else([])
  end

  @spec delete(Game.t()) :: Either.t(any(), term())
  def delete(%Game{id: id}) do
    Store.delete_item(@table_name, id)
  end
end
