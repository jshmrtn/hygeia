# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePrematureReleases do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason
  alias Hygeia.CaseContext.PrematureRelease.Reason

  def up do
    execute("""
    ALTER TYPE
      #{EndReason.type()}
      ADD VALUE IF NOT EXISTS 'immune' AFTER 'negative_test';
    """)

    execute("""
    ALTER TYPE
      #{EndReason.type()}
      ADD VALUE IF NOT EXISTS 'vaccinated' AFTER 'immune';
    """)

    Reason.create_type()

    create table(:premature_releases) do
      add :reason, Reason.type(), null: false
      add :phase_uuid, :binary_id, null: false
      add :case_uuid, references(:cases, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:premature_releases, [:case_uuid])

    execute("""
    CREATE FUNCTION
      premature_release_notification()
      RETURNS trigger AS $$
        DECLARE
          TRACER_UUID UUID;
        BEGIN
          SELECT
          INTO TRACER_UUID cases.tracer_uuid
          FROM cases
          WHERE
            cases.uuid = NEW.case_uuid AND
            cases.tracer_uuid IS NOT NULL AND
            (
              NULLIF(CURRENT_SETTING('versioning.originator_id', true), '') IS NULL OR
              cases.tracer_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid
            );

          IF FOUND THEN
            INSERT INTO notifications
              (uuid, body, user_uuid, inserted_at, updated_at) VALUES
              (
                MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                JSONB_BUILD_OBJECT('__type__', 'premature_release', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'premature_release_uuid', NEW.uuid),
                TRACER_UUID,
                NOW(),
                NOW()
              );
          END IF;

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      premature_releases_created_notification
      AFTER INSERT OR UPDATE ON premature_releases
      FOR EACH ROW EXECUTE PROCEDURE premature_release_notification();
    """)

    execute("""
    CREATE FUNCTION
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
    """)

    execute("""
    CREATE TRIGGER
      premature_releases_created_update_case
      AFTER INSERT OR UPDATE ON premature_releases
      FOR EACH ROW EXECUTE PROCEDURE premature_release_update_case();
    """)
  end
end
