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
      {:hygeia, in_umbrella: true},
      {:hygeia_telemetry, in_umbrella: true},
      {:hygeia_pdf_confirmation, in_umbrella: true},
      {:hygeia_gettext, in_umbrella: true},
      {:hygeia_cldr, in_umbrella: true},
      {:hygeia_iam, in_umbrella: true},
      {:phoenix, "~> 1.5.6"},
      {:phoenix_ecto, "~> 4.0"},
      # TODO: Remove override when Surface is released
      {:phoenix_live_view, "~> 0.15", override: true},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_active_link, "~> 0.3.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:surface, "~> 0.1"},
      {:ecto_psql_extras, "~> 0.4"},
      {:ueberauth, "~> 0.6", override: true},
      {:jsone, "~> 1.5", override: true},
      {:ueberauth_oidc, github: "rng2/ueberauth_oidc", tag: "0.0.1"},
      {:oidcc, github: "jshmrtn/oidcc", branch: "master", override: true},
      {:phoenix_live_view_dropzone, "~> 0.0"},
      {:csv, "~> 2.4"},
      {:plug_content_security_policy, "~> 0.2.1"},
      {:remote_ip, "~> 0.1"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      {:xlsxir, "~> 1.6.4"},
      {:mime, "~> 1.5"}
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
