defmodule Exkubia.MixProject do
  use Mix.Project

  def project do
    [
      app: :exkubia,
      version: "0.3.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Exkubia.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:remote_ip, "~> 0.2.0"},
      {:fs, "~> 6.0"},
      {:vapor, "~> 0.10"}
    ]
  end
end
