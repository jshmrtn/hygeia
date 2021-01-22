# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddSymptomStart do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute("""
    UPDATE
      cases update_case
    SET
      clinical = JSONB_SET(
        update_case.clinical,
        '{symptom_start}',
        phase->'start'
      )
    FROM
      cases select_case
    JOIN UNNEST(select_case.phases) AS phase
      ON phase->'details'->>'__type__' = 'index'
    WHERE
      update_case.uuid = select_case.uuid
    """)
  end
end
