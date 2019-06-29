defmodule TwhelpTest do
  use ExUnit.Case
  doctest Twhelp

  test "greets the world" do
    assert Twhelp.hello() == :world
  end
end
