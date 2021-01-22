# credo:disable-for-this-file Credo.Check.Readability.Specs
# TODO: Remove when https://github.com/elixir-gettext/gettext/issues/178 is fixed
defmodule Mix.Tasks.Gettext.Extract.Umbrella do
  @shortdoc "Run Gexttext Extract for all Umbrella Apps"

  @moduledoc """
  Run Gexttext Extract for all Umbrella Apps

  For documentation check `mix help gettext.extract`, all
  arguments are passed through directly.
  """
  use Mix.Task

  @recursive false

  def run(args) do
    unless Mix.Project.umbrella?() do
      msg =
        "Cannot run task gettext.extract.umbrella from place " <>
          "other than umbrella application root dir."

      Mix.raise(msg)
    end

    {:ok, _apps} = Application.ensure_all_started(:gettext)
    force_recompile_and_extract()

    Mix.Task.run("gettext.extract", args)
  end

  defp force_recompile_and_extract do
    Gettext.Extractor.enable()
    Mix.Task.run("compile", ["--force"])
  after
    Gettext.Extractor.disable()
  end
end
