defmodule MySuperTest do
  use ExUnit.Case
  doctest MySuper

  test "greets the world" do
    assert MySuper.hello() == :world
  end
end
