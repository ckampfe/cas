defmodule CellTest do
  use ExUnit.Case, async: true
  doctest Cas.Cell

  test "demonstration of the problem of concurrent read-after-write in ETS" do
    # same settings as we use for :cas_cell_table
    :ets.new(:cas_test_table, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    true = :ets.insert(:cas_test_table, {:value, 0})

    output_list =
      Enum.map(
        1..100,
        fn _i ->
          Task.async(fn ->
            [{:value, previous_i}] = :ets.lookup(:cas_test_table, :value)
            # normally you would use :ets.update_counter for incrementing an int,
            # but Cas.Cell is designed for complex data updates, not just incrementing ints,
            # but this is a demonstration that a read-write of ETS is not atomic
            true = :ets.insert(:cas_test_table, {:value, previous_i + 1})

            [{:value, updated_i}] = :ets.lookup(:cas_test_table, :value)
            updated_i
          end)
        end
      )
      |> Enum.map(fn task -> Task.await(task) end)
      |> Enum.sort()

    # there are 100 results
    assert Enum.count(output_list) == 100
    # ...but there are duplicates.
    # it is technically possible that this could fail
    # (and the updates could all succeed perfectly)
    # but it's unlikely and the point is that you can't rely on it
    assert Enum.count(Enum.uniq(output_list)) < 100
  end

  test "when concurrently updating, we see 1..100 (not in order) with no duplicates" do
    cell = Cas.Cell.new(0)

    output_list =
      Enum.map(1..100, fn _i ->
        Task.async(fn ->
          Cas.Cell.swap!(cell, fn previous ->
            # 11-21ms of random sleep.
            # when using Cas.Cell, you'd never put a side effect in here
            # like this, but this is a demonstration
            :timer.sleep(:rand.uniform(10) + 10)
            previous + 1
          end)
        end)
      end)
      |> Enum.map(fn task -> Task.await(task) end)
      |> Enum.sort()

    assert Enum.count(output_list) == 100
    # there are no duplicates,
    # and they exactly match the 1..100 range (after sorting)
    assert output_list == Enum.to_list(1..100)
  end
end
