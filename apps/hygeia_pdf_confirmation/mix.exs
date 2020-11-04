# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaPdfConfirmation.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :hygeia_pdf_confirmation,
      version: "0.0.0-noversion",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod or System.get_env("BUILD_EMBEDDED") in ["1", "true"],
      test_coverage: [tool: ExCoveralls],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hygeia, in_umbrella: true},
      {:briefly, "~> 0.3"},
      {:pdf_generator, "~> 0.6.2"},
      {:phoenix, "~> 1.5.6"},
      {:phoenix_html, "~> 2.11"},
      {:gettext, "~> 0.11"},
      {:excoveralls, "~> 0.4", runtime: false, only: [:test]}
    ]
  end
end
