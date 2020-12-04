# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsTransmissionCountryCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
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
