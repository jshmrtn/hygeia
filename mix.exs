# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Umbrella.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      name: "Hygeia",
      apps_path: "apps",
      version: "1.27.0-beta.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      dialyzer:
        [
          ignore_warnings: ".dialyzer_ignore.exs",
          list_unused_filters: true,
          plt_add_apps: [:mix]
        ] ++
          if (System.get_env("DIALYZER_PLT_PRIV") || "false") in ["1", "true"] do
            [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
          else
            []
          end,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test,
        "coveralls.xml": :test
      ],
      releases: [
        hygeia: [
          applications: [
            hygeia_web: :permanent,
            hygeia_api: :permanent,
            sentry_event_filter: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    [
      {:credo, "~> 1.4", runtime: false, only: [:dev]},
      {:dialyxir, "~> 1.0", runtime: false, only: [:dev]},
      {:ex_doc, "~> 0.24", runtime: false},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      # Override Reason: https://github.com/elixir-grpc/grpc#grpc-elixir
      {:gun, "~> 2.0.0", hex: :grpc_gun, override: true},
      {:sentry, "~> 8.0"},
      {:jason, "~> 1.1"},
      {:hackney, "~> 1.8"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["deps.get", "cmd mix setup"]
    ]
  end
end
