defmodule CowboyWsProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :cowboy_ws_proxy,
      version: "0.1.0",
      elixir: "~> 1.12",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CowboyWsProxy, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gun, "~> 2.0.0-rc.2"},
      {:cowboy, "~> 2.2"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
