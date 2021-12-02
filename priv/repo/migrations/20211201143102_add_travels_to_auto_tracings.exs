# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddTravelsToAutoTracings do
  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem
  alias Hygeia.AutoTracingContext.AutoTracing.Step

  @disable_ddl_transaction true

  def up do
    alter table(:auto_tracings) do
      add :has_travelled, :boolean
      add :travel, :map
    end

    execute("""
    ALTER TYPE
      #{Step.type()}
      ADD VALUE IF NOT EXISTS 'travel' AFTER 'clinical';
    """)

    execute("""
    ALTER TYPE
      #{Problem.type()}
      ADD VALUE IF NOT EXISTS 'high_risk_country_travel';
    """)
  end
end
