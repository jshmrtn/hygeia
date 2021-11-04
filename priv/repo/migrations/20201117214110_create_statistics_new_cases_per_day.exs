# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsNewCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE MATERIALIZED VIEW statistics_new_cases_per_day
        (tenant_uuid, type, sub_type, date, count)
        AS SELECT
          tenants.uuid, type, sub_type, date::date, COUNT(
            DISTINCT
            CASE WHEN phase IS NULL THEN NULL ELSE people.uuid END
          ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ARRAY['index', 'possible_index']) AS type
          LEFT JOIN UNNEST(ENUM_RANGE(NULL::case_phase_possible_index_type)) AS sub_type
            ON type = 'possible_index'
          CROSS JOIN tenants
          LEFT JOIN cases ON cases.tenant_uuid = tenants.uuid
          LEFT JOIN people ON people.uuid = cases.person_uuid
          LEFT JOIN UNNEST(cases.phases) AS phase
            ON (
              (phase->'details'->>'__type__') = type AND
              (phase->'details'->>'type')::case_phase_possible_index_type = sub_type AND
              COALESCE ((phase->>'start')::date, cases.inserted_at::date) = date
            )
          GROUP BY date, type, sub_type, tenants.uuid
          ORDER BY date, type, sub_type, tenants.uuid
      """,
      """
      DROP MATERIALIZED VIEW statistics_new_cases_per_day;
      """
    )

    create unique_index(:statistics_new_cases_per_day, [:tenant_uuid, :date, :type, :sub_type])
    create index(:statistics_new_cases_per_day, [:tenant_uuid])
    create index(:statistics_new_cases_per_day, [:date])
    create index(:statistics_new_cases_per_day, [:type])
    create index(:statistics_new_cases_per_day, [:sub_type])
  end
end
