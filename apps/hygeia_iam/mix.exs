# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaIam.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_iam,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
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
      extra_applications: [:logger],
      mod: {HygeiaIam.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oidcc, github: "jshmrtn/oidcc", branch: "master"},
      {:certifi, "~> 2.5"},
      {:jason, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:jose, "~> 1.10"}
    ]
  end
end
