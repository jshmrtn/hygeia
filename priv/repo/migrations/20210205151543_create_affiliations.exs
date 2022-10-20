# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateAffiliations do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Affiliation

  def up do
    Affiliation.Kind.create_type()

    create table(:affiliations) do
      add :kind, Affiliation.Kind.type()
      add :kind_other, :text
      add :person_uuid, references(:people, on_delete: :nothing), null: false
      add :organisation_uuid, references(:organisations, on_delete: :nothing), null: true
      add :comment, :text, null: true

      timestamps()
    end

    create index(:affiliations, [:person_uuid])
    create index(:affiliations, [:organisation_uuid])

    create constraint(:affiliations, :kind_other_required,
             check: """
             CASE
              WHEN kind = 'other' THEN kind_other IS NOT NULL
              ELSE kind_other IS NULL
             END
             """
           )

    create constraint(:affiliations, :comment_required,
             check: "organisation_uuid IS NOT NULL OR comment IS NOT NULL"
           )

    execute("""
    INSERT INTO
      organisations
      (uuid, name, address, inserted_at, updated_at)
    SELECT
      MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
      employer->>'name',
      (ARRAY_REMOVE(ARRAY_AGG(employer->'address'), NULL))[1],
      NOW(),
      NOW()
    FROM people
    CROSS JOIN UNNEST(people.employers) AS employer
    WHERE employer->>'name' NOT IN (SELECT name FROM organisations)
    GROUP BY employer->>'name'
    """)

    execute("""
    INSERT INTO
      affiliations
      (uuid, kind, person_uuid, organisation_uuid, inserted_at, updated_at)
    SELECT
      MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
      'employee'::#{Affiliation.Kind.type()},
      people.uuid,
      organisations.uuid,
      NOW(),
      NOW()
    FROM people
    CROSS JOIN UNNEST(people.employers) AS employer
    JOIN organisations ON organisations.name = employer->>'name'
    """)

    execute("""
    UPDATE
    people update
    SET
      contact_methods = update.contact_methods || new.supervisor
    FROM (
      SELECT
        internal.uuid,
        ARRAY_AGG(
          JSONB_BUILD_OBJECT(
            'type',
            'other',
            'value',
            TRIM(COALESCE(employer->>'supervisor_name', '') || ' ' || COALESCE(employer->>'supervisor_phone', '')),
            'comment',
            'Vorgesetzter'
          )
        ) AS supervisor
      FROM people internal
      JOIN UNNEST(internal.employers) AS employer
      ON employer->>'supervisor_name' IS NOT NULL OR employer->>'supervisor_phone' IS NOT NULL
      GROUP BY internal.uuid
    ) new
    WHERE update.uuid = new.uuid
    """)

    alter table(:people) do
      remove :fulltext
      remove :employers, {:list, :map}
    end

    execute("""
    ALTER
      TABLE people
      ADD fulltext TSVECTOR
        GENERATED ALWAYS AS (
          TO_TSVECTOR('german', uuid::text) ||
          TO_TSVECTOR('german', human_readable_id) ||
          TO_TSVECTOR('german', COALESCE(first_name, '')) ||
          TO_TSVECTOR('german', COALESCE(last_name, '')) ||
          JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(contact_methods, '$[*].value') ||
          JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(external_references, '$[*].value') ||
          COALESCE(JSONB_TO_TSVECTOR('german', address, '["all"]'), TO_TSVECTOR('german', ''))
        ) STORED
    """)

    create index(:people, [:fulltext], using: :gin)
  end
end
