defmodule Exkubia.Router do
  use Plug.Router
  require Logger

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

  get "/secret" do
    jwt = opts[:config].k8s_jwt
    vault_addr = opts[:config].vault_addr

    resp =
      if jwt && vault_addr do
        {:ok, %Finch.Response{body: body}} =
          Finch.build(
            :post,
            "#{vault_addr}/v1/auth/kubernetes/login",
            [{"Content-Type", "application/json"}],
            %{"role" => "webapp", "jwt" => jwt} |> Jason.encode!()
          )
          |> IO.inspect(label: "🔒")
          |> Finch.request(HttpClient)

        Logger.info("Body #{inspect(body)}")

        vault_token = Jason.decode!(body)["auth"]["client_token"]

        # Should stay secret ;-)
        Logger.info("Got vault_token #{inspect(vault_token)}")

        {:ok, %Finch.Response{body: body}} =
          Finch.build(
            :get,
            "#{vault_addr}/v1/secret/data/webapp/config",
            [{"Content-Type", "application/json"}, {"X-Vault-Token", "#{vault_token}"}]
          )
          |> Finch.request(HttpClient)

        secrets = Jason.decode!(body)

        "#{inspect(secrets["data"]["data"])}"
      else
        "😰"
      end

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(Plug.Conn.Status.code(:ok), resp)
  end

  get "/secrets" do
    {:ok, credentials1} = Exkubia.Secrets.secret(opts[:config].secrets_process, :credentials)
    {:ok, credentials2} = Exkubia.Secrets.secret(opts[:config].secrets_process, :credentials2)

    resp = """
    🤫1: #{credentials1}
    🤫2: #{credentials2}
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(Plug.Conn.Status.code(:ok), resp)
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

  get "/env" do
    resp = "#{System.get_env() |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)}"

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
