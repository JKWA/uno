defmodule Uno.Store do
  import Funx.Monad
  alias Funx.Monad.Either

  def create_table(table) when is_atom(table) do
    Either.from_try(fn ->
      :ets.new(table, [:named_table, :set, :public])
    end)
  end

  def drop_table(table) when is_atom(table) do
    Either.from_try(fn ->
      :ets.delete(table)
    end)
    |> map(fn _ -> table end)
  end

  def insert_item(table, %{id: id} = item) when is_atom(table) do
    Either.from_try(fn ->
      :ets.insert(table, {id, Map.from_struct(item)})
    end)
    |> map(fn _ -> item end)
  end

  def get_item(table, id) when is_atom(table) do
    Either.from_try(fn ->
      :ets.lookup(table, id)
    end)
    |> bind(fn
      [{_id, item}] -> Either.pure(item)
      [] -> Either.left(:not_found)
    end)
  end

  def get_all_items(table) when is_atom(table) do
    Either.from_try(fn ->
      :ets.tab2list(table)
    end)
    |> map(fn items ->
      Enum.map(items, fn {_, item} -> item end)
    end)
  end

  def delete_item(table, id) when is_atom(table) do
    Either.from_try(fn ->
      :ets.delete(table, id)
    end)
    |> map(fn _ -> id end)
  end
end
