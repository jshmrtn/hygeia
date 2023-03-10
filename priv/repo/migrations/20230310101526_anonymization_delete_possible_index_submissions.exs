# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AnonymizationDeletePossibleIndexSubmissions do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :anonymization_job, originator: :noone)
    end)

    execute("""
    DELETE
      FROM possible_index_submissions
      WHERE case_uuid IN (
        SELECT
          uuid
          FROM cases
          WHERE anonymized
      )
    """)
  end

  def down do
  end
end
