defmodule HumanReadableIdentifierGenerator.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :human_readable_identifier_generator,
      version: "0.0.0-noversion",
      build_path:
        if System.get_env("SEPARATE_ELIXIR_VERSION_BUILD") == "1" do
          "../../_build/#{System.version()}"
        else
          "../../_build"
        end,
      elixirc_paths: elixirc_paths(Mix.env()),
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      build_embedded: System.get_env("BUILD_EMBEDDED") == "1",
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:mix]
      ],
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  def application do
    [
      mod: {HumanReadableIdentifierGenerator.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:unidecode, "~> 0.0.2"},
      {:excoveralls, "~> 0.4", only: [:test], runtime: false}
    ]
  end
end
