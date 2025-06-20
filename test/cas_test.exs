defmodule CasTest do
  use ExUnit.Case
  doctest Cas

  test "greets the world" do
    assert Cas.hello() == :world
  end
end
