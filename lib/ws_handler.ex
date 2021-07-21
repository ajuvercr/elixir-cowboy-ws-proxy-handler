defmodule WsHandler do
  @moduledoc """
  Documentation for `CowboyWsProxy`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> CowboyWsProxy.hello()
      :world

  """
  @behaviour :cowboy_websocket

  def init(req, {param, default}) do
    ws = param.(req) || default

    new_state =
      %{}
      |> Map.put(:host, ws.host)
      |> Map.put(:path, ws.path)
      |> Map.put(:port, ws.port)
      |> Map.put(:ready, false)
      |> Map.put(:buffer, [])

    {:cowboy_websocket, req, new_state}
  end

  def websocket_init(state) do
    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 300
    }

    # conn :: pid()
    {:ok, conn} = :gun.open(to_charlist(state.host), state.port, connect_opts)

    {:ok, :http} = :gun.await_up(conn)

    # streamref :: StreamRef
    streamref = :gun.ws_upgrade(conn, to_charlist(state.path))

    new_state =
      state
      |> Map.put(:back_pid, conn)
      |> Map.put(:back_ref, streamref)

    {:ok, new_state}
  end

  def websocket_handle(message, state) do
    new_state =
      if state.ready do
        IO.inspect(message, label: "websocket frontend message")

        :ok = :gun.ws_send(state.back_pid, state.back_ref, message)
        state
      else
        IO.inspect(message,
          label: "websocket frontend message postponed (connection not started)"
        )

        buf = [message | state.buffer]
        Map.put(state, :buffer, buf)
      end

    {:ok, new_state}
  end

  def websocket_info({:gun_ws, _pid, _ref, msg}, state) do
    IO.inspect(msg, label: "websocket backend message")

    {:reply, msg, state}
  end

  def websocket_info({:gun_error, _gun_pid, _stream_ref, reason}, _state) do
    exit({:ws_upgrade_failed, reason})
  end

  def websocket_info({:gun_response, _gun_pid, _, _, status, headers}, _state) do
    IO.inspect({"Websocket upgrade failed.", headers}, label: "websocket all")
    exit({:ws_upgrade_failed, status, headers})
  end

  def websocket_info({:gun_upgrade, _, _, ["websocket"], _headers}, state) do
    IO.inspect("ws upgrade succesful", label: "websocket all")

    state.buffer
    |> Enum.reverse()
    |> Enum.each(fn x ->
      IO.inspect(x, label: "postponed sending message")
      :gun.ws_send(state.back_pid, state.back_ref, x)
    end)

    new_state =
      state
      |> Map.put(:ready, true)
      |> Map.put(:buffer, [])

    {:ok, new_state}
  end

  def websocket_info(info, state) do
    IO.inspect(info, label: "websocket unhandled info")

    {:ok, state}
  end

  def terminate(_reason, _req, state) do
    IO.inspect("Closing", label: "websocket all")
    :gun.shutdown(state.back_pid)
    :ok
  end
end
