defmodule Exkubia.LogConn do
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    remote_ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string()
    Logger.metadata(remote_ip: to_string(remote_ip))

    conn
  end
end
