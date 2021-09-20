# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaApi.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_api,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test,
        "coveralls.xml": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {HygeiaApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.5"},
      {:absinthe_error_payload, "1.0.1"},
      {:absinthe_phoenix, "~> 2.0.2"},
      {:absinthe_relay, "~> 1.5"},
      {:cors_plug, "~> 2.0"},
      {:dataloader, "~> 1.0"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      {:hackney, "~> 1.8"},
      {:hygeia_health, in_umbrella: true},
      {:hygeia, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.5"},
      {:phoenix_live_dashboard, "~> 0.4"},
      # TODO: Revert to released version when this PR is merged and released:
      # - https://github.com/ggpasqualino/plug_checkup/pull/66
      {:plug_checkup, github: "jshmrtn/plug_checkup", branch: "check_query_selector"},
      {:plug_cowboy, "~> 2.4"},
      {:remote_ip, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4 or ~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: []
    ]
  end
end
