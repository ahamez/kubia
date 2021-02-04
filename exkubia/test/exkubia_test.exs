defmodule ExkubiaTest do
  use ExUnit.Case
  doctest Exkubia

  test "greets the world" do
    assert Exkubia.hello() == :world
  end
end
