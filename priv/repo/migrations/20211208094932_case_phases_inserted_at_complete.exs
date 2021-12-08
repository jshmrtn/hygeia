# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CasePhasesInsertedAtComplete do
  use Hygeia, :migration

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    execute(
      """
      UPDATE
        cases update_case
        SET
          phases = replace_case.new_phases
        FROM (
          SELECT
            cases.uuid AS case_uuid,
            ARRAY_AGG(
              JSONB_BUILD_OBJECT('inserted_at', cases.inserted_at) ||
              phase
            ) AS new_phases
            FROM cases
            CROSS JOIN
              UNNEST(cases.phases)
              AS phase
            WHERE
              cases.uuid IN (
                SELECT DISTINCT
                  cases.uuid
                  FROM cases
                  JOIN
                    UNNEST(cases.phases)
                    AS phase
                    ON
                      phase->>'inserted_at' IS NULL
              )
            GROUP BY cases.uuid
        ) replace_case
        WHERE replace_case.case_uuid = update_case.uuid
      """,
      &noop/0
    )
  end
end
