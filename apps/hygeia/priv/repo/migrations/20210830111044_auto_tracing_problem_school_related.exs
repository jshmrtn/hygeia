defmodule Hygeia.Repo.Migrations.AutoTracingProblemSchoolRelated do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Problem.type()}
      ADD VALUE IF NOT EXISTS 'school_related';
    """)
  end
end
