# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.OrganisationDeleteCascade do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute("""
    DROP MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation;
    """)

    drop constraint(:positions, :positions_organisation_uuid_fkey)
    drop constraint(:positions, :positions_person_uuid_fkey)

    alter table(:positions, primary_key: false) do
      modify :organisation_uuid, references(:organisations, on_delete: :delete_all)
      modify :person_uuid, references(:people, on_delete: :delete_all)
    end

    drop constraint(:divisions, :divisions_organisation_uuid_fkey)

    alter table(:divisions, primary_key: false) do
      modify :organisation_uuid, references(:organisations, on_delete: :delete_all)
    end

    drop constraint(:affiliations, :affiliations_organisation_uuid_fkey)
    drop constraint(:affiliations, :affiliations_division_uuid_fkey)
    drop constraint(:affiliations, :affiliations_person_uuid_fkey)

    alter table(:affiliations, primary_key: false) do
      modify :organisation_uuid, references(:organisations, on_delete: :nilify_all), null: true
      modify :division_uuid, references(:divisions, on_delete: :nilify_all), null: true
      modify :person_uuid, references(:people, on_delete: :delete_all)
    end

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation
      (tenant_uuid, date, organisation_name, count)
      AS
      WITH ranked_active_cases AS (
        SELECT
          date::date AS date,
          cases.tenant_uuid AS tenant_uuid,
          organisations.name AS organisation_name,
          COUNT(cases.person_uuid) AS count,
          ROW_NUMBER() OVER (PARTITION BY date, tenant_uuid ORDER BY COUNT(cases.person_uuid) DESC)
        FROM cases
        CROSS JOIN unnest(cases.phases) AS phase
        CROSS JOIN GENERATE_SERIES(
          (phase.phase ->> 'start'::text)::date,
          (phase.phase ->> 'end'::text)::date,
          INTERVAL '1 day'
        ) AS date
        LEFT JOIN affiliations
          ON affiliations.person_uuid = cases.person_uuid
        LEFT JOIN organisations
          ON organisations.uuid = affiliations.organisation_uuid
        WHERE '{ "details": { "__type__": "index" }, "quarantine_order": true }'::jsonb <@ (phase)
        GROUP BY tenant_uuid, date, organisation_name
        HAVING COUNT(cases.person_uuid) > 0
        ORDER BY date, tenant_uuid, count DESC
      )
      SELECT tenant_uuid, date, organisation_name, count
      FROM ranked_active_cases
      WHERE row_number <= 100
    """)

    create unique_index(:statistics_active_cases_per_day_and_organisation, [
             :tenant_uuid,
             :date,
             :organisation_name
           ])

    create index(:statistics_active_cases_per_day_and_organisation, [:tenant_uuid])
    create index(:statistics_active_cases_per_day_and_organisation, [:date])

    create index(:statistics_active_cases_per_day_and_organisation, [:organisation_name])
  end
end
