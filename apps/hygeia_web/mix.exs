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
      elixir: "~> 1.12",
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
      {:mime, "~> 1.5 or ~> 2.0"},
      {:nebulex, "~> 2.0-rc"},
      {:oidcc, "~> 2.0.0-alpha"},
      {:phoenix, "~> 1.5"},
      # TODO: Revert to released version when this PR is merged and released:
      # - https://github.com/danhper/phoenix-active-link/pull/19
      {:phoenix_active_link, "~> 0.3.1",
       github: "jshmrtn/phoenix-active-link", branch: "phoenix_html_v3"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11 or ~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.16"},
      {:plug, "~> 1.12.1"},
      # TODO: Revert to released version when this PR is merged and released:
      # - https://github.com/ggpasqualino/plug_checkup/pull/66
      {:plug_checkup, github: "jshmrtn/plug_checkup", branch: "check_query_selector"},
      {:plug_content_security_policy, "~> 0.2.1"},
      {:plug_cowboy, "~> 2.4"},
      {:plug_dynamic, "~> 1.0"},
      {:remote_ip, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:shards, "~> 1.0"},
      # TODO: Update Surface
      # Pinned because of https://github.com/jshmrtn/hygeia/runs/3278558991?check_suite_focus=true
      {:surface, "0.6.1"},
      {:surface_formatter, "~> 0.2"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4 or ~> 1.0"}
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
