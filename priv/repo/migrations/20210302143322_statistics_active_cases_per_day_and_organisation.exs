# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsActiveCasesPerDayAndOrganisation do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation
        (tenant_uuid, date, organisation_uuid, count)
        AS
        WITH ranked_active_cases AS (
          SELECT
            date::date AS date,
            cases.tenant_uuid AS tenant_uuid,
            affiliations.organisation_uuid AS organisation_uuid,
            COUNT(cases.person_uuid) AS count,
            ROW_NUMBER() OVER (PARTITION BY date, tenant_uuid ORDER BY COUNT(cases.person_uuid) DESC)
          FROM cases
          CROSS JOIN unnest(cases.phases) AS phase
          CROSS JOIN GENERATE_SERIES(
            COALESCE((phase.phase ->> 'start'::text)::date, cases.inserted_at::date),
            COALESCE((phase.phase ->> 'end'::text)::date, CURRENT_DATE::date),
            INTERVAL '1 day'
          ) AS date
          LEFT JOIN affiliations
            ON affiliations.person_uuid = cases.person_uuid
          WHERE phase->'details'->>'__type__' = 'index'
          GROUP BY tenant_uuid, date, organisation_uuid
          HAVING COUNT(cases.person_uuid) > 0
          ORDER BY date, tenant_uuid, count DESC
        )
        SELECT tenant_uuid, date, organisation_uuid, count
        FROM ranked_active_cases
        WHERE row_number <= 100
      """,
      """
      DROP MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation;
      """
    )

    create unique_index(:statistics_active_cases_per_day_and_organisation, [
             :tenant_uuid,
             :date,
             :organisation_uuid
           ])

    create index(:statistics_active_cases_per_day_and_organisation, [:tenant_uuid])
    create index(:statistics_active_cases_per_day_and_organisation, [:date])

    create index(:statistics_active_cases_per_day_and_organisation, [:organisation_uuid])
  end
end
