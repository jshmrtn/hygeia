# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia,
      name: "Hygeia",
      version: "1.32.0-beta.2",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      gettext: [write_reference_comments: false, sort_by_msgid: true],
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      dialyzer:
        [
          ignore_warnings: ".dialyzer_ignore.exs",
          list_unused_filters: true,
          plt_add_apps: [:mix]
        ] ++
          if System.get_env("DIALYZER_PLT_PRIV", "false") in ["1", "true"] do
            [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
          else
            []
          end,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      extra_applications: [:logger, :runtime_tools, :eex, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

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
      {:briefly, "~> 0.3"},
      {:cadastre, "~> 0.2.0"},
      {:certifi, "~> 2.5"},
      {:credo, "~> 1.4", runtime: false, only: [:dev]},
      {:crontab, "~> 1.1"},
      # TODO: Revert back to the released version when the following PR is
      # merged and released:
      # - https://github.com/beatrichartz/csv/pull/104
      {:csv, "~> 2.4", github: "jshmrtn/csv", branch: "formular_escaping"},
      {:dialyxir, "~> 1.0", runtime: false, only: [:dev]},
      {:earmark, "~> 1.1"},
      {:ecto, "~> 3.7"},
      {:ecto_boot_migration, "~> 0.2"},
      {:ecto_enum, "~> 1.4"},
      {:ecto_psql_extras, "~> 0.4"},
      {:ecto_sql, "~> 3.4"},
      {:email_checker, "~> 0.1"},
      {:erlsom, "~> 1.5"},
      {:ex_cldr, "~> 2.24"},
      {:ex_cldr_calendars, "~> 1.17"},
      {:ex_cldr_dates_times, "~> 2.10"},
      {:ex_cldr_languages, "~> 0.3"},
      {:ex_cldr_lists, "~> 2.9"},
      {:ex_cldr_numbers, "~> 2.23"},
      {:ex_cldr_units, "~> 3.8"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]},
      {:ex_doc, "~> 0.24", runtime: false, only: [:dev]},
      {:ex_phone_number, "~> 0.2"},
      {:floki, ">= 0.27.0", only: :test},
      {:gen_smtp, "~> 1.0"},
      {:gettext, "~> 0.13", github: "elixir-gettext/gettext", branch: "master", override: true},
      # Override Reason: https://github.com/elixir-grpc/grpc#grpc-elixir
      {:gun, "~> 2.0.0", hex: :grpc_gun, override: true},
      {:hackney, "~> 1.8"},
      {:highlander, "~> 0.2"},
      {:human_readable_identifier_generator, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:jose, "~> 1.10"},
      {:jsone, "~> 1.5", override: true},
      {:libcluster, "~> 3.2"},
      {:mail, "~> 0.2"},
      {:mime, "~> 1.5 or ~> 2.0"},
      {:mox, "~> 1.0", only: :test},
      {:nebulex, "~> 2.0-rc"},
      {:oidcc, "~> 2.0.0-alpha"},
      {:paginator, "~> 1.0"},
      {:pdf_generator, "~> 0.6.2"},
      {:phoenix, "~> 1.6"},
      # TODO: Revert to released version when this PR is merged and released:
      # - https://github.com/danhper/phoenix-active-link/pull/19
      {:phoenix_active_link, "~> 0.3.1",
       github: "jshmrtn/phoenix-active-link", branch: "phoenix_html_v3"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11 or ~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.16"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug, "~> 1.12.1"},
      # TODO: Revert to released version when this PR is merged and released:
      # - https://github.com/ggpasqualino/plug_checkup/pull/66
      {:plug_checkup, github: "jshmrtn/plug_checkup", branch: "check_query_selector"},
      {:plug_content_security_policy, "~> 0.2.1"},
      {:plug_cowboy, "~> 2.4"},
      {:plug_dynamic, "~> 1.0"},
      {:polymorphic_embed, "~> 1.7"},
      {:postgrex, ">= 0.0.0"},
      {:remote_ip, "~> 1.0"},
      {:sedex, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:shards, "~> 1.0"},
      # TODO: Update Surface
      # Pinned because of https://github.com/jshmrtn/hygeia/runs/3278558991?check_suite_focus=true
      {:surface, "~> 0.6.1"},
      {:surface_formatter, "~> 0.2"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_metrics_prometheus, "~> 1.0"},
      {:telemetry_poller, "~> 0.4 or ~> 1.0"},
      {:tzdata, "~> 1.0"},
      {:websms, "~> 1.0.0-alpha"},
      {:xlsxir, "~> 1.6.4"},
      {:zitadel_api, "~> 1.0-rc"}
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
      setup: ["deps.get", "ecto.reset", "cmd npm install --prefix assets"],
      "ecto.setup":
        case Mix.env() do
          :test ->
            ["ecto.create", "ecto.migrate"]

          _env ->
            [
              "ecto.create",
              "ecto.load --skip-if-loaded --quiet",
              "ecto.migrate",
              "run priv/repo/seeds.exs"
            ]
        end,
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
