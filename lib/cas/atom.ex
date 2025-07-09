defmodule Cas.Atom do
  @table :cas_atom_table

  @derive {Inspect, except: [:id, :table]}
  @enforce_keys [:id, :table]
  defstruct [:id, :table]

  @doc """
  Create a new atom.
  Must be initialized with a value.

  ## Examples

    iex> Cas.Atom.new(1)
    #Cas.Atom<...>
  """
  def new(value, table \\ @table) do
    id = System.unique_integer()

    :ets.insert(table, {id, value})

    %__MODULE__{id: id, table: table}
  end

  @doc """
  Get the current value of the atom.

  ## Examples

    iex> atom = Cas.Atom.new(1)
    iex> Cas.Atom.get(atom)
    1
  """
  def get(%__MODULE__{id: id, table: table}) do
    [{_, value}] = :ets.lookup(table, id)
    value
  end

  @doc """
  Atomically swaps the value of the atom to be `f.(current_value)`.
  Note that `f` may be run multiple times, so it must not cause side effects.
  Returns the new value of the atom.

  ## Examples

    iex> atom = Cas.Atom.new(1)
    iex> Cas.Atom.swap!(atom, fn v -> v + 99 end)
    100
  """
  def swap!(%__MODULE__{id: id, table: table} = atom, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(table, id)

    new_value =
      if args do
        f.(old_value, args)
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
      swap!(atom, f, args)
    end
  end

  @doc """
  set the atom's value to `value`.
  returns `value`

  ## Examples

    iex> atom = Cas.Atom.new(1)
    iex> Cas.Atom.reset!(atom, "hello")
    "hello"
  """
  def reset!(%__MODULE__{id: id, table: table}, value) do
    :ets.insert(table, {id, value})
    value
  end

  @doc """
  Like `swap!`, but returns the previous and the new value of the atom.

  ## Examples

    iex> atom = Cas.Atom.new(1)
    iex> Cas.Atom.swap_old_and_new!(atom, fn v -> v + 99 end)
    {1, 100}
  """
  def swap_old_and_new!(%__MODULE__{id: id, table: table} = atom, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(table, id)

    new_value =
      if args do
        f.(old_value, args)
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
      swap!(atom, f, args)
    end
  end

  @doc """
  Delete this atom.
  Subsequent calls to `get`, `swap`, etc., will fail.

  ## Examples

    iex> atom = Cas.Atom.new(1)
    iex> Cas.Atom.delete(atom)
    true
  """
  def delete(%__MODULE__{id: id, table: table}) do
    :ets.delete(table, id)
  end
end
