# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
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
      mod: {Hygeia.Application, []},
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
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.0"},
      {:ecto_boot_migration, "~> 0.2"},
      {:email_checker, "~> 0.1"},
      # TODO: Replace with released version when https://github.com/izelnakri/paper_trail/pull/112 is released
      {:paper_trail, github: "jshmrtn/paper_trail", branch: "dev"},
      {:ecto_enum, "~> 1.4"},
      {:cadastre, "~> 0.1.4"},
      {:human_readable_identifier_generator, "~> 1.0"},
      {:polymorphic_embed, "~> 0.12"},
      {:ex_phone_number, "~> 0.2"},
      {:mox, "~> 1.0", only: :test},
      {:websms, "~> 1.0.0-alpha"},
      {:paginator, "~> 1.0"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup":
        case Mix.env() do
          :test -> ["ecto.create", "ecto.migrate"]
          _env -> ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]
        end,
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
