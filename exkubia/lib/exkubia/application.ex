defmodule Exkubia.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    config = configure!()
    config = Map.put(config, :secrets_process, Exkubia.Secrets)
    config = Map.put(config, :fortune_process, Exkubia.Fortune)

    Logger.debug("#{inspect(config)}")

    children = [
      {Exkubia.Secrets, [config: config, name: config.secrets_process]},
      {Plug.Cowboy,
       scheme: :http, plug: {Exkubia.Router, [config: config]}, options: [port: config.port]},
      {Exkubia.Fortune, [config: config, name: config.fortune_process]}
    ]

    opts = [strategy: :one_for_one, name: Exkubia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure!() do
    providers = [
      %Vapor.Provider.Env{
        bindings: [
          {:fortune_path, "KUBIA_FORTUNE_PATH", default: "./fortune.txt"},
          {:secrets_dir_path, "KUBIA_SECRETS_DIR_PATH", default: "./secrets/"},
          {:port, "KUBIA_HTTP_PORT", default: 8080, map: &String.to_integer/1}
        ]
      }
      # %Vapor.Provider.File{
      #   path: "kubia_config.toml",
      #   bindings: [
      #     {:fortune_path, "kubia.fortune_path"},
      #     {:port, "kubia.port", default: 8080, map: &String.to_integer/1}
      #   ]
      # }
    ]

    Vapor.load!(providers)
  end
end
