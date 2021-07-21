defmodule CowboyWsProxyTest do
  use ExUnit.Case
  doctest CowboyWsProxy

  test "greets the world" do
    assert CowboyWsProxy.hello() == :world
  end
end
