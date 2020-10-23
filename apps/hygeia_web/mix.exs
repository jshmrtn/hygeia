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
      {:phoenix, "~> 1.5.6"},
      {:phoenix_ecto, "~> 4.0"},
      # TODO: Switch back to released version when surface works with it
      {:phoenix_live_view,
       github: "phoenixframework/phoenix_live_view",
       ref: "597c5ddf8af2ca39216a3fe5a44c066774de3abd",
       override: true},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_active_link, "~> 0.2.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # TODO: Replace with released version as soon as it is compatible with LiveView 0.15
      {:phoenix_live_dashboard, github: "maennchen/phoenix_live_dashboard", branch: "master"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:hygeia, in_umbrella: true},
      {:hygeia_telemetry, in_umbrella: true},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ex_cldr, "~> 2.17"},
      {:ex_cldr_numbers, "~> 2.15"},
      {:ex_cldr_lists, "~> 2.6"},
      {:ex_cldr_dates_times, "~> 2.5"},
      {:ex_cldr_calendars, "~> 1.10"},
      {:ex_cldr_units, "~> 3.2"},
      {:ex_cldr_languages, "~> 0.2.1"},
      {:surface, github: "msaraiva/surface", tag: "v0.1.0-rc.1"},
      # Force Newer Dependency for surface
      {:nimble_parsec, "~> 0.5.3"},
      {:ecto_psql_extras, "~> 0.2"},
      {:ueberauth, "~> 0.6", override: true},
      {:jsone, "~> 1.5", override: true},
      {:ueberauth_oidc, github: "rng2/ueberauth_oidc", tag: "0.0.1"},
      {:oidcc, github: "jshmrtn/oidcc", branch: "master", override: true},
      {:certifi, "~> 2.5"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]}
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
