# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateVaccinationShots do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType

  @vaccine_type_conversion_searches %{
    "moderna" => ["moderna", "1273", "spikevax", "moserna", "moterna"],
    "pfizer" => [
      "pfizer",
      "biontech",
      "Biotec",
      "binotech",
      "bion tech",
      "Bnt162b2",
      "comirnaty",
      "comimaty",
      "Cominaraty",
      "Comitary",
      "Corminaty",
      "tozinameran",
      "Pfeiser",
      "Pfyser",
      "Physer",
      "Phiser",
      "Piser",
      "Pizer",
      "pfyzer",
      "Pficer",
      "Pfizer",
      "Pfister"
    ],
    "janssen" => [
      "janssen",
      "johnson",
      "Jahnsen",
      "Jensson",
      "Jhonson",
      "J&J",
      "jonsen",
      "Ad26.COV2.S"
    ],
    "astra_zeneca" => ["astra", "AZD1222", "Vaxzevria", "Covishield", "zeneca"],
    "sinopharm" => ["Sinopharm", "BIBP", "Vero Cell"],
    "sinovac" => ["sinovac", "CoronaVac"],
    "covaxin" => ["covaxin"],
    "novavax" => ["novavax", "CoV2373", "Nuvaxovid", "Covovax"]
  }

  @statistics_vaccination_breakthroughs_per_day_up_sql """
  CREATE MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
    (tenant_uuid, date, count)
    AS
      WITH
        last_positive_test_dates AS (
          SELECT
            tests.case_uuid AS case_uuid,
            MAX(COALESCE(tests.tested_at, tests.laboratory_reported_at)) AS test_date
            FROM tests
            GROUP BY tests.case_uuid
        ),
        case_count_dates AS (
          SELECT
            cases.uuid AS uuid,
            cases.tenant_uuid AS tenant_uuid,
            cases.person_uuid AS person_uuid,
            COALESCE(
              last_positive_test_dates.test_date,
              (cases.clinical->>'symptom_start')::date,
              (index_phases->>'order_date')::date,
              (index_phases->>'inserted_at')::date,
              cases.inserted_at::date
            ) AS count_date
            FROM cases
            JOIN
              UNNEST(cases.phases)
              AS index_phases
              ON index_phases->'details'->>'__type__' = 'index'
            LEFT JOIN
              last_positive_test_dates
              ON last_positive_test_dates.case_uuid = cases.uuid
        )
      SELECT
        tenants.uuid AS tenant_uuid,
        date::date,
        COUNT(DISTINCT vaccination_shot_validity.person_uuid) AS count
        FROM GENERATE_SERIES(
          LEAST((SELECT MIN(count_date) from case_count_dates), CURRENT_DATE - INTERVAL '1 year'),
          CURRENT_DATE,
          interval '1 day'
        ) AS date
        CROSS JOIN tenants
        LEFT JOIN
          case_count_dates
          ON
            tenants.uuid = case_count_dates.tenant_uuid AND
            date = case_count_dates.count_date
        LEFT JOIN
          vaccination_shot_validity
          ON
            vaccination_shot_validity.range @> date::date AND
            vaccination_shot_validity.person_uuid = case_count_dates.person_uuid
        GROUP BY
          date,
          tenants.uuid
        ORDER BY
          date,
          tenants.uuid
  """

  @vaccination_shot_validity_up_query """
  SELECT
    result.person_uuid,
    result.vaccination_shot_uuid,
    result.range
    FROM (
      SELECT
        people.uuid AS person_uuid,
        vaccination_shots.uuid AS vaccination_shot_uuid,
        CASE
          WHEN (
            ROW_NUMBER() OVER (
              PARTITION BY people.uuid
              ORDER BY vaccination_shots.date
            ) >= 2 OR
            people.convalescent_externally OR
            COALESCE(
              (index_phases->>'order_date')::date,
              (index_phases->>'inserted_at')::date,
              cases.inserted_at::date
            ) >= vaccination_shots.date
          ) THEN
            DATERANGE(
              vaccination_shots.date,
              (vaccination_shots.date + INTERVAL '1 year')::date
            )
          ELSE NULL
        END AS range
        FROM people
        JOIN
          vaccination_shots
          ON vaccination_shots.person_uuid = people.uuid
        LEFT JOIN
          cases
          ON cases.person_uuid = people.uuid
        LEFT JOIN
          UNNEST(cases.phases)
          AS index_phases
          ON index_phases->'details'->>'__type__' = 'index'
        WHERE
          vaccination_shots.vaccine_type IN ('pfizer', 'moderna')
    ) AS result
    WHERE result.range IS NOT NULL
  UNION
  SELECT
    people.uuid AS person_uuid,
    vaccination_shots.uuid,
    DATERANGE(
      (vaccination_shots.date + INTERVAL '22 day')::date,
      (vaccination_shots.date + INTERVAL '1 year 22 day')::date
    ) AS range
  FROM people
  JOIN
    vaccination_shots
    ON vaccination_shots.person_uuid = people.uuid
  WHERE
    vaccination_shots.vaccine_type = 'janssen';
  """

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    alter table(:people) do
      add :is_vaccinated, :boolean
      add :convalescent_externally, :boolean, default: false, null: false
    end

    VaccineType.create_type()

    create table(:vaccination_shots) do
      add :vaccine_type, VaccineType.type(), null: false
      add :vaccine_type_other, :string
      add :date, :date, null: false
      add :person_uuid, references(:people, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:vaccination_shots, [:vaccine_type])
    create index(:vaccination_shots, [:person_uuid])
    create index(:vaccination_shots, [:person_uuid, :vaccine_type])
    create unique_index(:vaccination_shots, [:person_uuid, :date])

    create constraint(:vaccination_shots, :vaccine_type_other_required,
             check: """
             CASE
              WHEN vaccine_type = 'other' THEN vaccine_type_other IS NOT NULL
              ELSE vaccine_type_other IS NULL
             END
             """
           )

    execute(
      """
      CREATE TRIGGER
        vaccination_shots_versioning_insert
        AFTER INSERT ON vaccination_shots
        FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
      """,
      """
      DROP TRIGGER vaccination_shots_versioning_insert ON vaccination_shots;
      """
    )

    execute(
      """
      CREATE TRIGGER
        vaccination_shots_versioning_update
        AFTER UPDATE ON vaccination_shots
        FOR EACH ROW EXECUTE PROCEDURE versioning_update();
      """,
      """
      DROP TRIGGER vaccination_shots_versioning_update ON vaccination_shots;
      """
    )

    execute(
      """
      CREATE TRIGGER
        vaccination_shots_versioning_delete
        AFTER DELETE ON vaccination_shots
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """,
      """
      DROP TRIGGER vaccination_shots_versioning_delete ON vaccination_shots;
      """
    )

    execute(
      """
      SET pg_trgm.similarity_threshold = 0.1;
      """,
      &noop/0
    )

    execute(
      """
      UPDATE
        people
        SET
          is_vaccinated = CASE
            WHEN people.vaccination->>'done' = 'true' AND people.vaccination->'jab_dates'->>-1 IS NOT NULL THEN TRUE
            WHEN people.vaccination->>'done' = 'false' THEN FALSE
            ELSE NULL
          END
      """,
      &noop/0
    )

    execute(
      """
      INSERT
        INTO vaccination_shots
        (uuid, vaccine_type, vaccine_type_other, date, person_uuid, inserted_at, updated_at)
        SELECT
          GEN_RANDOM_UUID(),
          CASE
            #{for {type, searches} <- @vaccine_type_conversion_searches, search <- searches, into: "", do: "WHEN '#{search}' <% (people.vaccination->>'name') THEN '#{type}'::#{VaccineType.type()} "}
            ELSE 'other'::#{VaccineType.type()}
          END AS vaccine_type,
          CASE
            #{for {_type, searches} <- @vaccine_type_conversion_searches, search <- searches, into: "", do: "WHEN '#{search}' <% (people.vaccination->>'name') THEN NULL "}
            ELSE COALESCE(people.vaccination->>'name', 'unknown')
          END AS vaccine_type_other,
          date::date AS date,
          people.uuid AS person_uuid,
          NOW() AS inserted_at,
          NOW() AS updated_at
          FROM people
          CROSS JOIN
            JSONB_ARRAY_ELEMENTS_TEXT(people.vaccination->'jab_dates')
            AS date
          WHERE
            people.vaccination->>'done' = 'true' AND
            people.vaccination->'jab_dates'->>-1 IS NOT NULL AND
            date IS NOT NULL;
      """,
      """
      UPDATE
        people
        SET
          vaccination = search.vaccination
        FROM (
          SELECT
            vaccination_shots.person_uuid AS person_uuid,
            JSONB_BUILD_OBJECT(
              'uuid',
              GEN_RANDOM_UUID(),
              'done',
              TRUE,
              'name',
              CASE
                #{for {name, type} <- VaccineType.map(), type != :other, into: "", do: "WHEN MAX(vaccination_shots.vaccine_type) = '#{type}' THEN '#{name}' "}
                WHEN MAX(vaccination_shots.vaccine_type) = 'other' THEN MAX(vaccination_shots.vaccine_type_other)
              END,
              'jab_dates',
              ARRAY_AGG(vaccination_shots.date)
            ) AS vaccination
          FROM vaccination_shots
          GROUP BY vaccination_shots.person_uuid
        ) search
        WHERE search.person_uuid = people.uuid;
      """
    )

    alter table(:people) do
      remove :vaccination, :map
    end

    execute(
      """
      CREATE
        VIEW vaccination_shot_validity
        AS #{vaccination_shot_validity_up_query()}
      """,
      """
      DROP
        VIEW vaccination_shot_validity;
      """
    )

    execute(
      statistics_vaccination_breakthroughs_per_day_up_sql(),
      """
      DROP
        MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
      """
    )

    create unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    create index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    create index(:statistics_vaccination_breakthroughs_per_day, [:date])

    execute(&noop/0, fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)
  end

  def statistics_vaccination_breakthroughs_per_day_up_sql,
    do: @statistics_vaccination_breakthroughs_per_day_up_sql

  def vaccination_shot_validity_up_query, do: @vaccination_shot_validity_up_query
end
