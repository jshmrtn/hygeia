# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.PrematureReleaseNoNotifications do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE OR REPLACE FUNCTION
        premature_release_update_case()
        RETURNS trigger AS $$
          BEGIN
            UPDATE
              cases AS update_case
            SET
              phases = ARRAY_REPLACE(
                update_case.phases,
                subquery.search_phase,
                subquery.update_phase
              ),
              status = 'done'
            FROM
              (
                SELECT
                  uuid,
                  phase AS search_phase,
                  JSONB_SET(
                    JSONB_SET(
                      JSONB_SET(
                        phase,
                        '{send_automated_close_email}',
                        TO_JSONB(FALSE)
                      ),
                      '{end}',
                      TO_JSONB(CURRENT_DATE)
                    ),
                    '{details,end_reason}',
                    TO_JSONB(NEW.reason)
                  ) AS update_phase
                FROM cases
                CROSS JOIN UNNEST(cases.phases) AS phase
                WHERE uuid = NEW.case_uuid AND (phase->>'uuid')::uuid = new.phase_uuid
              ) AS subquery
            WHERE update_case.uuid = subquery.uuid;

            RETURN NEW;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
        CREATE OR REPLACE FUNCTION
          premature_release_update_case()
          RETURNS trigger AS $$
            BEGIN
              UPDATE
                cases AS update_case
              SET
                phases = ARRAY_REPLACE(
                  update_case.phases,
                  subquery.search_phase,
                  subquery.update_phase
                ),
                status = 'done'
              FROM
                (
                  SELECT
                    uuid,
                    phase AS search_phase,
                    JSONB_SET(
                      JSONB_SET(
                        phase,
                        '{end}',
                        TO_JSONB(CURRENT_DATE)
                      ),
                      '{details,end_reason}',
                      TO_JSONB(NEW.reason)
                    ) AS update_phase
                  FROM cases
                  CROSS JOIN UNNEST(cases.phases) AS phase
                  WHERE uuid = NEW.case_uuid AND (phase->>'uuid')::uuid = new.phase_uuid
                ) AS subquery
              WHERE update_case.uuid = subquery.uuid;

              RETURN NEW;
            END
          $$ LANGUAGE plpgsql;
      """
    )
  end
end
