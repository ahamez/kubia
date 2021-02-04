import Config

config :logger,
  compile_time_purge_matching: [
    [application: :remote_ip]
  ]

config :logger, :console,
  format: "[$time][$level][$metadata] $message\n",
  metadata: [:remote_ip, :request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
