# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingProblemResidencyOutsideCountry do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Problem.type()}
      ADD VALUE IF NOT EXISTS 'residency_outside_country';
    """)
  end
end
