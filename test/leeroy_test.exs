defmodule LeeroyTest do
  use ExUnit.Case
  doctest Leeroy

  test "greets the world" do
    assert Leeroy.hello() == :world
  end
end
