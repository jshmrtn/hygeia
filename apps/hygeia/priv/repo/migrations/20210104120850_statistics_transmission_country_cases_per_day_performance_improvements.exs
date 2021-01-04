# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsTransmissionCountryCasesPerDayPerformanceImprovements do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop unique_index(:statistics_transmission_country_cases_per_day, [
           :tenant_uuid,
           :date,
           :country
         ])

    drop index(:statistics_transmission_country_cases_per_day, [:tenant_uuid])
    drop index(:statistics_transmission_country_cases_per_day, [:date])
    drop index(:statistics_transmission_country_cases_per_day, [:country])

    execute(
      """
      DROP MATERIALIZED VIEW statistics_transmission_country_cases_per_day;
      """,
      """
      CREATE MATERIALIZED VIEW statistics_transmission_country_cases_per_day
        (tenant_uuid, date, country, count)
        AS WITH cases_with_transmissions AS
          (SELECT
            cases.tenant_uuid,
            cases.person_uuid,
            (UNNEST(cases.phases) ->> 'start')::date AS phase_start,
            cases.inserted_at::date AS case_inserted_at,
            transmissions.inserted_at::date AS country_inserted_at,
            infection_place -> 'address' ->> 'country' AS country
          FROM cases
          LEFT JOIN transmissions ON transmissions.recipient_case_uuid = cases.uuid
          )
        SELECT
          tenants.uuid AS tenant_uuid,
          date::date,
          country,
          COUNT(DISTINCT
            CASE
              WHEN
                tenants.uuid = cases_with_transmissions.tenant_uuid AND
                COALESCE(country_inserted_at, phase_start, case_inserted_at) = date
              THEN person_uuid
              ELSE NULL
            END
          ) AS count
        FROM GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
          CURRENT_DATE,
          interval '1 day'
        ) AS date, cases_with_transmissions
        CROSS JOIN tenants
        GROUP BY date, tenants.uuid, country
        ORDER BY date, tenants.uuid, country
      """
    )

    execute(
      """
      CREATE MATERIALIZED VIEW statistics_transmission_country_cases_per_day
        (tenant_uuid, date, country, count)
        AS
          WITH
            countries AS (
              SELECT
                DISTINCT transmissions.infection_place->'address'->>'country' AS country
              FROM transmissions
            ),
            cases_with_transmissions AS (
              SELECT
                cases.tenant_uuid AS cmp_tenant_uuid,
                cases.person_uuid AS cmp_person_uuid,
                COALESCE(
                  transmissions.inserted_at::date,
                  (phase ->> 'start')::date,
                  cases.inserted_at::date
                ) AS cmp_date,
                transmissions.infection_place->'address'->>'country' AS cmp_country
              FROM cases
              LEFT JOIN transmissions
                ON transmissions.recipient_case_uuid = cases.uuid
              CROSS JOIN UNNEST(cases.phases) AS phase
              WHERE NOT transmissions.infection_place->'address'->>'country' IS NULL
            )
          SELECT
            tenants.uuid AS tenant_uuid,
            date::date,
            countries.country,
            COUNT(DISTINCT cases_with_transmissions.cmp_person_uuid) AS count
          FROM GENERATE_SERIES(
            LEAST(
              (SELECT MIN(inserted_at::date) from cases),
              CURRENT_DATE - INTERVAL '1 year'
            ),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          CROSS JOIN countries
          LEFT JOIN cases_with_transmissions
            ON cases_with_transmissions.cmp_tenant_uuid = tenants.uuid AND
              cases_with_transmissions.cmp_date = date AND
              cases_with_transmissions.cmp_country = countries.country
          GROUP BY date, tenants.uuid, countries.country
          ORDER BY date, tenants.uuid, countries.country
      """,
      """
      DROP MATERIALIZED VIEW statistics_transmission_country_cases_per_day;
      """
    )

    create unique_index(:statistics_transmission_country_cases_per_day, [
             :tenant_uuid,
             :date,
             :country
           ])

    create index(:statistics_transmission_country_cases_per_day, [:tenant_uuid])
    create index(:statistics_transmission_country_cases_per_day, [:date])
    create index(:statistics_transmission_country_cases_per_day, [:country])
  end
end
