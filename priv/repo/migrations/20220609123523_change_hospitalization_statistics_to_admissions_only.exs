# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.ChangeHospitalizationStatisticsToAdmissionsOnly do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    DROP MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day;
    """)

    execute("""
      CREATE MATERIALIZED VIEW statistics_hospital_admission_cases_per_day
        (tenant_uuid, date, count)
        AS WITH cases_with_hospitalizations AS (
          SELECT
            cases.tenant_uuid,
            cases.person_uuid,
            hospitalizations.start AS start_date
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
            cases_with_hospitalizations.start_date = date
          )
        GROUP BY date, tenants.uuid
        ORDER BY date, tenants.uuid
    """)

    create unique_index(:statistics_hospital_admission_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_hospital_admission_cases_per_day, [:tenant_uuid])
    create index(:statistics_hospital_admission_cases_per_day, [:date])
  end
end
