defmodule Cas.Atom do
  @table :cas_atom_table

  @enforce_keys [:id]
  defstruct [:id]

  @doc """
  Create a new atom.
  Must be initialized with a value.
  """
  def new(value) do
    id = System.unique_integer()

    :ets.insert(@table, {id, value})

    %__MODULE__{id: id}
  end

  @doc """
  Get the current value of the atom.
  """
  def get(atom) do
    [{_, value}] = :ets.lookup(@table, atom.id)
    value
  end

  @doc """
  Atomically swaps the value of the atom to be `f.(current_value)`.
  Note that `f` may be run multiple times, so it must not cause side effects.
  Returns the new value of the atom.
  """
  def swap!(%__MODULE__{id: id} = atom, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(@table, id)

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
          @table,
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
  """
  def reset!(atom, value) do
    :ets.insert(@table, {atom.id, value})
    value
  end

  @doc """
  Like `swap!`, but returns the previous and the new value of the atom.
  """
  def swap_old_and_new!(%__MODULE__{id: id} = atom, f, args \\ nil) do
    [{^id, old_value} = old_kv] = :ets.lookup(@table, id)

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
          @table,
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
  """
  def delete(atom) do
    :ets.delete(@table, atom.id)
  end
end
