# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingProblemNoReaction do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem
  alias Hygeia.VersionContext.Version.Origin

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Problem.type()}
      ADD VALUE IF NOT EXISTS 'no_reaction';
    """)

    execute("""
    ALTER TYPE
      #{Origin.type()}
      ADD VALUE IF NOT EXISTS 'detect_no_reaction_cases_job';
    """)
  end
end
