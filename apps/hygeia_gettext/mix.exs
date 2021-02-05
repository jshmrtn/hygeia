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
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      compilers: [:gettext] ++ Mix.compilers(),
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
      {:gettext, "~> 0.11"},
      {:sentry, "~> 8.0"}
    ]
  end
end
