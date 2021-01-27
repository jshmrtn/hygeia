# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FurtherBagMedCompliance do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE case_phase_possible_index_type
    ADD VALUE IF NOT EXISTS 'outbreak';
    """)

    execute("""
    ALTER TYPE case_phase_possible_index_type
    ADD VALUE IF NOT EXISTS 'covid_app';
    """)

    execute("""
    ALTER TYPE case_phase_possible_index_type
    ADD VALUE IF NOT EXISTS 'other';
    """)

    execute("""
    ALTER TYPE test_reason
    ADD VALUE IF NOT EXISTS 'quarantine_end';
    """)

    execute("""
    ALTER TYPE case_phase_index_end_reason
    ADD VALUE IF NOT EXISTS 'other';
    """)

    execute("""
    ALTER TYPE case_phase_possible_index_end_reason
    ADD VALUE IF NOT EXISTS 'other';
    """)
  end

  def down do
  end
end
