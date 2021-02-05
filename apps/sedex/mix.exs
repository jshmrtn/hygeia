# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Sedex.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :sedex,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Sedex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hygeia_xml, in_umbrella: true},
      {:jose, "~> 1.11"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.17", override: true},
      {:sweet_xml, "~> 0.6"},
      {:briefly, "~> 0.3.0", only: [:test]},
      {:sentry, "~> 8.0"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]}
    ]
  end
end
