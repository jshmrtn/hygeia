# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.HospitalizationsOwnEntity do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    create table(:hospitalizations) do
      add :start, :date
      add :end, :date
      add :organisation_uuid, references(:organisations, on_delete: :nilify_all)
      add :case_uuid, references(:cases, on_delete: :delete_all)

      timestamps()
    end

    execute("""
    CREATE TRIGGER
      hospitalizations_versioning_insert
      AFTER INSERT ON hospitalizations
      FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
    """)

    execute("""
    CREATE TRIGGER
      hospitalizations_versioning_update
      AFTER UPDATE ON hospitalizations
      FOR EACH ROW EXECUTE PROCEDURE versioning_update();
    """)

    execute("""
    CREATE TRIGGER
      hospitalizations_versioning_delete
      AFTER DELETE ON hospitalizations
      FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
    """)

    execute("""
    INSERT INTO
      hospitalizations
      ("uuid", "start", "end", "organisation_uuid", "case_uuid", "inserted_at", "updated_at")
      SELECT
        (hospitalization->>'uuid')::uuid,
        (hospitalization->>'start')::date,
        (hospitalization->>'end')::date,
        organisations.uuid,
        cases.uuid,
        NOW(),
        NOW()
        FROM cases
        CROSS JOIN UNNEST(cases.hospitalizations) AS hospitalization
        LEFT JOIN organisations
          ON organisations.uuid = (hospitalization->>'organisation_uuid')::uuid
    """)

    execute("""
    DROP MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day;
    """)

    execute("""
      CREATE MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day
        (tenant_uuid, date, count)
        AS WITH cases_with_hospitalizations AS (
          SELECT
            cases.tenant_uuid,
            cases.person_uuid,
            hospitalizations.start AS start_date,
            COALESCE(
              hospitalizations.end,
              CURRENT_DATE
            ) AS end_date
          FROM cases
          JOIN hospitalizations ON hospitalizations.case_uuid = cases.uuid
        )
        SELECT
          tenants.uuid,
          date::date,
          COUNT(DISTINCT cases_with_hospitalizations.person_uuid) AS count
        FROM GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
          CURRENT_DATE,
          interval '1 day'
        ) AS date
        CROSS JOIN tenants
        LEFT JOIN cases_with_hospitalizations
          ON (
            tenants.uuid = cases_with_hospitalizations.tenant_uuid AND
            cases_with_hospitalizations.end_date >= date AND
            cases_with_hospitalizations.start_date <= date
          )
        GROUP BY date, tenants.uuid
        ORDER BY date, tenants.uuid
    """)

    create unique_index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_hospitalization_cases_per_day, [:date])

    alter table(:cases) do
      remove :hospitalizations, {:array, :map}
    end
  end
end
