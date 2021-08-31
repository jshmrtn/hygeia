# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaGettext.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_gettext,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      compilers: [:gettext] ++ Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      gettext: [write_reference_comments: false, sort_by_msgid: true],
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
      # TODO: Revert back to released version when the following commit is released:
      # - https://github.com/elixir-gettext/gettext/commit/565b965cb90d88259d8ed9f686337010ca8a4d43
      {:gettext, "~> 0.13", github: "elixir-gettext/gettext", branch: "master", override: true},
      {:ex_cldr_messages, "~> 0.10.0"}
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
