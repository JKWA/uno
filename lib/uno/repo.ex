defmodule Uno.Repo do
  import Funx.Monad
  alias Funx.Monad.Either
  alias Uno.Store
  alias Uno.Game

  @table_name :uno

  def create_table do
    Store.create_table(@table_name)
  end

  def save(%Game{} = game) do
    Store.insert_item(@table_name, game)
  end

  def get(id) do
    Store.get_item(@table_name, id)
    |> map(fn data -> struct(Game, data) end)
  end

  def list do
    Store.get_all_items(@table_name)
    |> map(fn items -> Enum.map(items, fn item -> struct(Game, item) end) end)
    |> Either.get_or_else([])
  end

  def delete(%Game{id: id}) do
    Store.delete_item(@table_name, id)
  end
end
