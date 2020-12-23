# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.BagMedCompliance do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Transmission.InfectionPlace
  alias Hygeia.EctoType.NOGA

  def up do
    InfectionPlace.Type.create_type()
    NOGA.Section.create_type()
    NOGA.Code.create_type()

    execute("""
    ALTER TYPE test_reason
      ADD VALUE IF NOT EXISTS 'convenience'
      BEFORE 'contact_tracing';
    """)

    execute("""
    ALTER TYPE test_kind
      ADD VALUE IF NOT EXISTS 'antigen_quick';
    """)

    execute("""
    ALTER TYPE test_kind
      ADD VALUE IF NOT EXISTS 'antibody';
    """)

    alter table(:people) do
      add :vaccination, :map
      add :profession_category, :noga_code
      add :profession_category_main, :noga_section
    end

    execute("""
    UPDATE
      people
    SET
      profession_category = CASE
        WHEN professions.name = 'Spital' THEN '861'::noga_code
        WHEN professions.name = 'Praxis' THEN '862'::noga_code
        WHEN professions.name = 'Heim' THEN '87'::noga_code
        WHEN professions.name = 'Apotheke' THEN '477'::noga_code
        WHEN professions.name = 'Kindertagesstätte' THEN '889'::noga_code
        WHEN professions.name = 'Volksschule' THEN '853'::noga_code
        WHEN professions.name = 'Oberstufe' THEN '853'::noga_code
        WHEN professions.name = 'Gymnasium / Berufsschule' THEN '853'::noga_code
        WHEN professions.name = 'Sicherheit: Polizei, Securitas' THEN '842'::noga_code
        WHEN professions.name = 'ÖV: Bus, Bahn, Schiff, Bergbahn' THEN '49'::noga_code
        WHEN professions.name = 'Verkauf' THEN '47'::noga_code
      END,
      profession_category_main = CASE
        WHEN professions.name = 'Spital' THEN 'Q'::noga_section
        WHEN professions.name = 'Praxis' THEN 'Q'::noga_section
        WHEN professions.name = 'Heim' THEN 'Q'::noga_section
        WHEN professions.name = 'Apotheke' THEN 'G'::noga_section
        WHEN professions.name = 'Spitex' THEN 'Q'::noga_section
        WHEN professions.name = 'Kindertagesstätte' THEN 'Q'::noga_section
        WHEN professions.name = 'Volksschule' THEN 'P'::noga_section
        WHEN professions.name = 'Oberstufe' THEN 'P'::noga_section
        WHEN professions.name = 'Gymnasium / Berufsschule' THEN 'P'::noga_section
        WHEN professions.name = 'Sicherheit: Polizei, Securitas' THEN 'O'::noga_section
        WHEN professions.name = 'ÖV: Bus, Bahn, Schiff, Bergbahn' THEN 'H'::noga_section
        WHEN professions.name = 'Verkauf' THEN 'G'::noga_section
        WHEN professions.name = 'Gastronomie / Veranstaltungen' THEN 'I'::noga_section
        WHEN professions.name = 'Öffentliche Verwaltung' THEN 'O'::noga_section
        WHEN professions.name = 'Büro' THEN 'M'::noga_section
        WHEN professions.name = 'Bau' THEN 'F'::noga_section
        WHEN professions.name = 'Rentner' THEN NULL::noga_section
        WHEN professions.name = 'Arbeitssuchend' THEN NULL::noga_section
        WHEN professions.name = 'Sonstiges' THEN NULL::noga_section
      END
    FROM professions
    WHERE
      NOT people.profession_uuid IS NULL AND
      people.profession_uuid = professions.uuid
    """)

    alter table(:people) do
      remove :profession_uuid
    end

    drop table(:professions)

    execute("""
    UPDATE
      transmissions
    SET
      infection_place = JSONB_SET(
        transmissions.infection_place,
        '{type}',
        TO_JSONB(CASE
          WHEN infection_place_types.name = 'Arbeitsplatz' THEN 'work_place'::infection_place_type
          WHEN infection_place_types.name = 'Armee, Zivilschutz' THEN 'army'::infection_place_type
          WHEN infection_place_types.name = 'Asylzentrum' THEN 'asyl'::infection_place_type
          WHEN infection_place_types.name = 'Chor, Gesangsverein, Orchester' THEN 'choir'::infection_place_type
          WHEN infection_place_types.name = 'Diskothek, Tanzclub, Nachtclub' THEN 'club'::infection_place_type
          WHEN infection_place_types.name = 'Eigener Haushalt' THEN 'hh'::infection_place_type
          WHEN infection_place_types.name = 'Einrichtung der Sekundarstufe II, tertiäre Bildungseinrichtung oder Weiterbildungsstätte' THEN 'high_school'::infection_place_type
          WHEN infection_place_types.name = 'Einrichtung zur familienergänzenden Kinderbetreuung' THEN 'childcare'::infection_place_type
          WHEN infection_place_types.name = 'Erotiksalon / Prostitutionsdienste' THEN 'erotica'::infection_place_type
          WHEN infection_place_types.name = 'Flugzeug oder Reise' THEN 'flight'::infection_place_type
          WHEN infection_place_types.name = 'Gesundheitseinrichtung (Spital, Klinik, Arztpraxis, Praxis für Gesundheitspflege, Einrichtung von Gesundheitsfachpersonen nach Bundesrecht und kantonalem Recht)' THEN 'medical'::infection_place_type
          WHEN infection_place_types.name = 'Hotel, Unterkunftsort, Campingplatz, Stellplatz für Wohnmobile' THEN 'hotel'::infection_place_type
          WHEN infection_place_types.name = 'Kinderheim, Behindertenheim' THEN 'child_home'::infection_place_type
          WHEN infection_place_types.name = 'Kino/Theater/Konzert' THEN 'cinema'::infection_place_type
          WHEN infection_place_types.name = 'Läden / Markt' THEN 'shop'::infection_place_type
          WHEN infection_place_types.name = 'Obligatorische Schule' THEN 'school'::infection_place_type
          WHEN infection_place_types.name = 'Öffentliche oder private Veranstaltung <300 Personen' THEN 'less_300'::infection_place_type
          WHEN infection_place_types.name = 'Öffentliche oder private Veranstaltung >300 Personen' THEN 'more_300'::infection_place_type
          WHEN infection_place_types.name = 'Öffentliche Verkehrsmittel, Seilbahnen' THEN 'public_transp'::infection_place_type
          WHEN infection_place_types.name = 'Persönliche Dienstleistung mit Körperkontakt (z.B. Friseure, Massagestudio)' THEN 'massage'::infection_place_type
          WHEN infection_place_types.name = 'Pflegeheim' THEN 'nursing_home'::infection_place_type
          WHEN infection_place_types.name = 'Religiöse Versammlungen / Beerdigungen' THEN 'religion'::infection_place_type
          WHEN infection_place_types.name = 'Restaurant, Bar' THEN 'restaurant'::infection_place_type
          WHEN infection_place_types.name = 'Schul-/Pfadfinderlager' THEN 'school_camp'::infection_place_type
          WHEN infection_place_types.name = 'Sportliche Betätigung in der Halle' THEN 'indoor_sport'::infection_place_type
          WHEN infection_place_types.name = 'Sportliche Betätigung im Freien' THEN 'outdoor_sport'::infection_place_type
          WHEN infection_place_types.name = 'Treffen mit Familie / Freunden' THEN 'gathering'::infection_place_type
          WHEN infection_place_types.name = 'Zoos, Tierparks, Gärten' THEN 'zoo'::infection_place_type
          WHEN infection_place_types.name = 'anderer Ort' THEN 'other'::infection_place_type
        END)
      )
    FROM infection_place_types
    WHERE
      NOT transmissions.infection_place->>'type_uuid' IS NULL AND
      infection_place_types.uuid = (transmissions.infection_place->>'type_uuid')::uuid
    """)

    execute("""
    UPDATE
      transmissions
    SET
      infection_place = transmissions.infection_place - 'type_uuid'
    FROM infection_place_types
    """)

    drop unique_index(:statistics_active_infection_place_cases_per_day, [
           :tenant_uuid,
           :date,
           :infection_place_type
         ])

    drop index(:statistics_active_infection_place_cases_per_day, [:tenant_uuid])
    drop index(:statistics_active_infection_place_cases_per_day, [:date])
    drop index(:statistics_active_infection_place_cases_per_day, [:infection_place_type])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_infection_place_cases_per_day;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_infection_place_cases_per_day
    (tenant_uuid, date, infection_place_type, count) AS
    WITH person_date_infection_place AS
      (
        SELECT
          cases.tenant_uuid AS cmp_tenant_uuid,
          cases.person_uuid AS cmp_person_uuid,
          (transmissions.infection_place->>'type')::infection_place_type AS cmp_infection_place_type,
          cmp_date::date
        FROM cases
        LEFT JOIN transmissions
            ON transmissions.recipient_case_uuid = cases.uuid
        CROSS JOIN UNNEST(cases.phases) AS phase
        CROSS JOIN
          GENERATE_SERIES( COALESCE ((phase ->> 'start')::date, cases.inserted_at::date), COALESCE ((phase ->> 'end')::date, CURRENT_DATE), interval '1 day' ) AS cmp_date
      )
    SELECT
      tenants.uuid,
      day::date AS date,
      infection_place_type,
      COUNT(DISTINCT person_date_infection_place.cmp_person_uuid) AS count
    FROM
      GENERATE_SERIES(
        LEAST((SELECT MIN(inserted_at::date) FROM cases), CURRENT_DATE - INTERVAL '1 year'), CURRENT_DATE, interval '1 day' ) AS day
        CROSS JOIN tenants
        CROSS JOIN UNNEST(ENUM_RANGE(NULL::infection_place_type) || ARRAY[NULL::infection_place_type]) AS infection_place_type
        LEFT JOIN person_date_infection_place
          ON ( tenants.uuid = person_date_infection_place.cmp_tenant_uuid
            AND day = person_date_infection_place.cmp_date
            AND (
              infection_place_type = person_date_infection_place.cmp_infection_place_type
              OR
              (
                infection_place_type IS NULL
                AND person_date_infection_place.cmp_infection_place_type IS NULL
              )
            )
          )
      GROUP BY day, tenants.uuid, infection_place_type
      ORDER BY day, tenants.uuid, infection_place_type
    """)

    create unique_index(:statistics_active_infection_place_cases_per_day, [
             :tenant_uuid,
             :date,
             :infection_place_type
           ])

    create index(:statistics_active_infection_place_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_infection_place_cases_per_day, [:date])
    create index(:statistics_active_infection_place_cases_per_day, [:infection_place_type])

    drop table(:infection_place_types)
  end
end
