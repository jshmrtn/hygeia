# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaWeb.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_web,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      mod: {HygeiaWeb.Application, []},
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
      {:csv, "~> 2.4"},
      {:earmark, "~> 1.1"},
      {:ecto_psql_extras, "~> 0.4"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      {:floki, ">= 0.27.0", only: :test},
      {:hackney, "~> 1.8"},
      {:hygeia_cldr, in_umbrella: true},
      {:hygeia_gettext, in_umbrella: true},
      {:hygeia_health, in_umbrella: true},
      {:hygeia_iam, in_umbrella: true},
      {:hygeia, in_umbrella: true},
      {:hygeia_pdf_confirmation, in_umbrella: true},
      {:hygeia_telemetry, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:jsone, "~> 1.5", override: true},
      {:mime, "~> 1.5"},
      {:nebulex, "~> 2.0-rc"},
      {:oidcc, github: "jshmrtn/oidcc", branch: "master", override: true},
      {:phoenix, "~> 1.5.6"},
      {:phoenix_active_link, "~> 0.3.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.15"},
      {:plug_checkup, "~> 0.6"},
      {:plug_content_security_policy, "~> 0.2.1"},
      {:plug_cowboy, "~> 2.5.0"},
      {:plug_dynamic, "~> 1.0"},
      {:remote_ip, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:shards, "~> 1.0"},
      {:surface, "~> 0.3"},
      {:surface_formatter, "~> 0.2"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:xlsxir, "~> 1.6.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
