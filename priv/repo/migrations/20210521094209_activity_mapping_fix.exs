# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.ActivityMappingFix do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Case.Status

  def change do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    ALTER TYPE
      #{Status.type()}
      ADD VALUE IF NOT EXISTS 'canceled';
    """)

    alter table(:transmissions) do
      add :comment, :text, null: true
    end

    execute("""
    UPDATE transmissions
      SET
        comment = infection_place->>'activity_mapping',
        infection_place = infection_place - 'activity_mapping_executed' - 'activity_mapping'
    """)

    alter table(:possible_index_submissions) do
      add :comment, :text, null: true
    end

    execute("""
    UPDATE possible_index_submissions
      SET
        comment = infection_place->>'activity_mapping',
        infection_place = infection_place - 'activity_mapping_executed' - 'activity_mapping'
    """)
  end
end
