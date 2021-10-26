# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingPossibleIndexProblem do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Problem.type()}
      ADD VALUE IF NOT EXISTS 'possible_index_submission';
    """)
  end
end
