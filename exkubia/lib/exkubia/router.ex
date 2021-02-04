defmodule Exkubia.Router do
  use Plug.Router

  plug(RemoteIp)
  plug(Plug.RequestId)
  plug(Exkubia.LogConn)
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch, builder_opts())

  get "/health" do
    conn
    |> send_resp(Plug.Conn.Status.code(:ok), "")
  end

  get "/fortune" do
    conn = fetch_query_params(conn)

    env =
      case Map.fetch(conn.query_params, "env") do
        {:ok, _value} ->
          """

           Env:
          #{System.get_env() |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)}

          """

        _ ->
          ""
      end

    fortune = Exkubia.Fortune.fortune(opts[:config].fortune_process)
    {:ok, hostname} = :inet.gethostname()
    version = Application.spec(:exkubia)[:vsn]

    resp = """
    This is your host #{hostname} (version #{version}).

    Your IP is #{conn.remote_ip |> :inet_parse.ntoa() |> to_string()}.
    #{env}
    Here's your fortune:
    #{fortune}
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(Plug.Conn.Status.code(:ok), resp)
  end

  get "/ready" do
    conn
    |> send_resp(Plug.Conn.Status.code(:ok), "")
  end

  match _ do
    send_resp(conn, Plug.Conn.Status.code(:not_found), "💣")
  end
end
