# Cas



Provides `Cas.Cell`, a direct analog to Clojure's [atom](https://clojure.org/reference/atoms), to provide (as Clojure says) "a way to manage shared, synchronous, independent state".

An cell is as an alternative to Elixir's [Agent](https://hexdocs.pm/elixir/1.18.4/Agent.html), or building your own GenServer to manage a piece of state. It's specifically useful when you have a piece of state that you want to share between and update from a number of processes.


[![Elixir CI](https://github.com/ckampfe/cas/actions/workflows/elixir.yml/badge.svg)](https://github.com/ckampfe/cas/actions/workflows/elixir.yml)

## Examples

```elixir
alias Cas.Cell

# Create an cell
cell = Cell.new(1)

# Get the value of an cell
Cell.get(cell)
#=> 1

# Swap values into an cell by applying a function to the
# current value of the cell.
# This is free from race conditions between the read of the current
# value and writing to the current value, because the
# underlying ETS API guarantees that `select_replace/2` is
# cellic and isolated.
#
# This means that an arbitrary number of processes can be swapping
# things into the cell concurrently, and they will always update the cell cellically.
# More concretely, this means the value passed to `f` will never be outdated.
# The value returned by `f` will always be derived from the most recent value of the cell,
# uncorrupted by other concurrent writers.
Cell.swap!(cell, fn i -> i + 1 end)
#=> 2
Cell.swap!(cell, fn i -> i + 1 end)
#=> 3

# reset the value of the cell
Cell.reset!(cell, 99)
#=> 99

# same as `swap!`, but return both the old value and the new value
Cell.swap_old_and_new!(cell, fn i -> i + 1 end)
#=> {99, 100}

# delete an cell's backing storage
Cell.delete(cell)
#=> true
```

## More detail

`Cas.Cell` uses ETS rather than processes, so it avoids the overhead of process mailboxes and message sends in favor of cellic compare-and-swaps in ETS itself.

This is possible because ETS provides a mechanism to do cellic compare-and-swap via [select_replace/2](https://www.erlang.org/doc/apps/stdlib/ets.html#select_replace/2). I only recently discovered that ETS provided this functionality, and once I did I knew I had to build this.

Because `Cas.Cell` uses ETS, unused cells will leak if they are not deleted, since they correspond 1:1 with rows in an ETS table.
