defmodule CowboyWsProxy do
  @moduledoc """
  Documentation for `CowboyWsProxy`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> CowboyWsProxy.hello()
      :world

  """
  def start(_argv, _args) do
    default = %{
      host: "localhost",
      port: 8080,
      path: "/"
    }

    f = fn (req) -> nil end

    routes =
      :cowboy_router.compile([
        {:_,
         [
           {:_, WsHandler, {
             f, default
           }}
         ]}
      ])

    require Logger
    # start an http server
    :cowboy.start_clear(
      :hello_http,
      [port: 4001],
      %{env: %{dispatch: routes}}
    )
  end
end
