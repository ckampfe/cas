# Cas

Provides `Cas.Atom`, a direct analog to Clojure's [atom](https://clojure.org/reference/atoms), to provide (as Clojure says) "a way to manage shared, synchronous, independent state".

An atom is as an alternative to Elixir's [Agent](https://hexdocs.pm/elixir/1.18.4/Agent.html), or building your own GenServer to manage a piece of state. It's specifically useful when you have a piece of state that you want to share between and update from a number of processes.


## Examples

```elixir
alias Cas.Atom

# Create an atom
atom = Atom.new(1)

# Get the value of an atom
Atom.get(atom)
#=> 1

# Swap values into an atom by applying a function to the
# current value of the atom.
# This is free from race conditions between the read of the current
# value and writing to the current value, because the
# underlying ETS API guarantees that `select_replace/2` is
# atomic and isolated.
#
# This means that an arbitrary number of processes can be swapping
# things into the atom concurrently, and the
Atom.swap!(atom, fn i -> i + 1 end)
#=> 2
Atom.swap!(atom, fn i -> i + 1 end)
#=> 3

# reset the value of the atom
Atom.reset!(atom, 99)
#=> 99

# same as `swap!`, but return both the old value and the new value
Atom.swap_old_and_new!(atom, fn i -> i + 1 end)
#=> {99, 100}

# delete an atom's backing storage
Atom.delete(atom)
#=> true
```

## More detail

`Cas.Atom` uses ETS rather than processes, so it avoids the overhead of process mailboxes and message sends in favor of atomic compare-and-swaps in ETS itself.

This is possible because ETS provides a mechanism to do atomic compare-and-swap via [select_replace/2](https://www.erlang.org/doc/apps/stdlib/ets.html#select_replace/2). I only recently discovered that ETS provided this functionality, and once I did I knew I had to build this.

Because `Cas.Atom` uses ETS, unused atoms will leak if they are not deleted, since they correspond 1:1 with rows in an ETS table.
