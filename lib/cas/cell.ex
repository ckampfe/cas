defmodule Cas.Cell do
  @table :cas_cell_table

  @derive {Inspect, except: [:id, :table]}
  @enforce_keys [:id, :table]
  defstruct [:id, :table]

  @doc """
  Create a new cell.
  Must be initialized with a value.

  ## Examples

      iex> Cas.Cell.new(1)
      #Cas.Cell<...>
  """
  def new(value, table \\ @table) do
    id = System.unique_integer()

    :ets.insert(table, {id, value})

    %__MODULE__{id: id, table: table}
  end

  @doc """
  Get the current value of the cell.

  ## Examples

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.get(cell)
      1
  """
  def get(%__MODULE__{id: id, table: table}) do
    [{_, value}] = :ets.lookup(table, id)
    value
  end

  @doc """
  Atomically swaps the value of the cell to be `f.(current_value)`.
  Note that `f` may be run multiple times, so it must not cause side effects.
  Returns the new value of the cell.

  ## Examples

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.swap!(cell, fn v -> v + 99 end)
      100

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.swap!(cell, fn v, a, b, c -> v + a + b + c end, [4, 5, 6])
      16
  """
  def swap!(%__MODULE__{id: id, table: table} = cell, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(table, id)

    new_value =
      if args do
        apply(f, [old_value | args])
      else
        f.(old_value)
      end

    new_kv = {id, new_value}

    successful_swap? =
      1 ==
        :ets.select_replace(
          table,
          [{old_kv, [], [{:const, new_kv}]}]
        )

    if successful_swap? do
      new_value
    else
      swap!(cell, f, args)
    end
  end

  @doc """
  set the cell's value to `value`.
  returns `value`

  ## Examples

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.reset!(cell, "hello")
      "hello"
  """
  def reset!(%__MODULE__{id: id, table: table}, value) do
    :ets.insert(table, {id, value})
    value
  end

  @doc """
  Like `swap!`, but returns the previous and the new value of the cell.

  ## Examples

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.swap_old_and_new!(cell, fn v -> v + 99 end)
      {1, 100}

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.swap_old_and_new!(cell, fn v, a, b, c -> v + a + b + c end, [4, 5, 6])
      {1, 16}
  """
  def swap_old_and_new!(%__MODULE__{id: id, table: table} = cell, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(table, id)

    new_value =
      if args do
        apply(f, [old_value | args])
      else
        f.(old_value)
      end

    new_kv = {id, new_value}

    successful_swap? =
      1 ==
        :ets.select_replace(
          table,
          [{old_kv, [], [{:const, new_kv}]}]
        )

    if successful_swap? do
      {old_value, new_value}
    else
      swap!(cell, f, args)
    end
  end

  @doc """
  Delete this cell.
  Subsequent calls to `get`, `swap`, etc., will fail.

  ## Examples

      iex> cell = Cas.Cell.new(1)
      iex> Cas.Cell.delete(cell)
      true
  """
  def delete(%__MODULE__{id: id, table: table}) do
    :ets.delete(table, id)
  end
end
