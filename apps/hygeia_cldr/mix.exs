# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaCldr.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_cldr,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      deps: deps(),
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # TODO: Revert back to stable version as soon as it is available
      {:ex_cldr, "~> 2.24.0-rc"},
      {:ex_cldr_calendars, "~> 1.17.0-rc"},
      {:ex_cldr_dates_times, "~> 2.10.0-rc"},
      {:ex_cldr_languages, "~> 0.3.0-rc"},
      {:ex_cldr_lists, "~> 2.9.0-rc"},
      {:ex_cldr_numbers, "~> 2.23.0-rc"},
      {:ex_cldr_units, "~> 3.8.0-rc"},
      {:hygeia_gettext, in_umbrella: true},
      {:tzdata, "~> 1.0"}
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
