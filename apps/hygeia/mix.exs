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
      compilers: [:gettext] ++ Mix.compilers(),
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
      {:cadastre, "~> 0.2.0"},
      {:crontab, "~> 1.1"},
      {:csv, "~> 2.4"},
      {:ecto_boot_migration, "~> 0.2"},
      {:ecto_enum, "~> 1.4"},
      # TODO: Loosen Restriction when version is available again
      {:ecto, "~> 3.4 and < 3.6.1"},
      {:ecto_sql, "~> 3.4"},
      {:email_checker, "~> 0.1"},
      {:erlsom, "~> 1.5"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      {:ex_phone_number, "~> 0.2"},
      {:gen_smtp, "~> 1.0"},
      {:gun, "~> 2.0.0", hex: :grpc_gun, override: true},
      {:highlander, "~> 0.2"},
      {:human_readable_identifier_generator, "~> 1.0"},
      {:hygeia_cldr, in_umbrella: true},
      {:hygeia_cluster, in_umbrella: true},
      {:hygeia_gettext, in_umbrella: true},
      {:hygeia_iam, in_umbrella: true},
      {:jason, "~> 1.0"},
      {:jsone, "~> 1.5", override: true},
      {:mail, "~> 0.2"},
      {:mox, "~> 1.0", only: :test},
      {:paginator, "~> 1.0"},
      {:phoenix, "~> 1.5.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:polymorphic_embed, "~> 1.3"},
      {:postgrex, ">= 0.0.0"},
      {:sedex, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:websms, "~> 1.0.0-alpha"},
      # TODO: Loosen Restriction for RC
      {:zitadel_api, "1.0.0-rc.2"}
    ]
  end

  @ecto_setup ["ecto.create", "ecto.load --skip-if-loaded --quiet", "ecto.migrate"]

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["ecto.reset"],
      "ecto.setup":
        case Mix.env() do
          :test -> @ecto_setup
          _env -> @ecto_setup ++ ["run priv/repo/seeds.exs"]
        end,
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
