# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VersioningNative do
  use Ecto.Migration

  alias Hygeia.VersionContext.Version

  def up do
    Version.Origin.create_type()
    Version.Event.create_type()

    drop index(:versions, [:item_id, :item_type])

    alter table(:versions) do
      remove :meta
      remove :id
      add :uuid, :binary_id, null: true
      add :item_pk, :map, null: true
      add :item_table, :text, null: true
      modify :event, :text, null: false
    end

    execute("""
    ALTER TABLE versions
      ALTER COLUMN origin
        TYPE #{Version.Origin.type()}
        USING CASE
          WHEN origin = 'web' THEN 'web'::#{Version.Origin.type()}
          WHEN origin = 'api' THEN 'api'::#{Version.Origin.type()}
          WHEN origin = 'user_sync_job' THEN 'user_sync_job'::#{Version.Origin.type()}
          WHEN origin = 'case_close_email_job' THEN 'case_close_email_job'::#{
      Version.Origin.type()
    }
          WHEN origin = 'email_sender' THEN 'email_sender'::#{Version.Origin.type()}
          WHEN origin = 'sms_sender' THEN 'sms_sender'::#{Version.Origin.type()}
          ELSE 'migration'::#{Version.Origin.type()}
        END,
      ALTER COLUMN event
        TYPE #{Version.Event.type()}
        USING CASE
          WHEN event = 'insert' THEN 'insert'::#{Version.Event.type()}
          WHEN event = 'update' THEN 'update'::#{Version.Event.type()}
          WHEN event = 'delete' THEN 'delete'::#{Version.Event.type()}
        END
    """)

    execute("""
    UPDATE versions
      SET
        uuid = MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
        item_pk = JSONB_BUILD_OBJECT('uuid', item_id),
        item_table = CASE
          WHEN item_type = 'Affiliation' THEN 'affiliations'
          WHEN item_type = 'Case' THEN 'cases'
          WHEN item_type = 'Division' THEN 'divisions'
          WHEN item_type = 'Email' THEN 'emails'
          WHEN item_type = 'InfectionPlaceType' THEN 'infection_place_types'
          WHEN item_type = 'Note' THEN 'notes'
          WHEN item_type = 'Organisation' THEN 'organisations'
          WHEN item_type = 'Person' THEN 'people'
          WHEN item_type = 'PossibleIndexSubmission' THEN 'possible_index_submissions'
          WHEN item_type = 'Profession' THEN 'professions'
          WHEN item_type = 'ProtocolEntry' THEN 'protocol_entries'
          WHEN item_type = 'SedexExport' THEN 'sedex_exports'
          WHEN item_type = 'SMS' THEN 'sms'
          WHEN item_type = 'SystemMessage' THEN 'system_messages'
          WHEN item_type = 'Tenant' THEN 'tenants'
          WHEN item_type = 'Transmission' THEN 'transmissions'
          WHEN item_type = 'User' THEN 'users'
        END
    """)

    alter table(:versions) do
      modify :item_pk, :map, null: false
      modify :uuid, :binary_id, null: false, primary_key: true
      remove :item_id
      modify :origin, Version.Origin.type(), null: false
      remove :item_type
    end

    create index(:versions, [:item_pk, :item_table])

    execute("""
    CREATE FUNCTION
      jsonb_equal(A JSONB, B JSONB)
      RETURNS BOOLEAN AS $$
        BEGIN
          RETURN A @> B AND A <@ B;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE FUNCTION
      versioning_pk(NEW JSONB, TABLE_NAME REGCLASS, TABLE_SCHEMA NAME)
      RETURNS JSONB AS $$
        DECLARE
          PK JSONB := '{}'::jsonb;
          PRIMARY_KEYS RECORD;
        BEGIN
          FOR PRIMARY_KEYS IN
            SELECT
              pg_attribute.attname AS field_name
            FROM pg_index, pg_class, pg_attribute, pg_namespace
            WHERE
              pg_class.oid = TABLE_NAME AND
              indrelid = pg_class.oid AND
              nspname =  TABLE_SCHEMA AND
              pg_class.relnamespace = pg_namespace.oid AND
              pg_attribute.attrelid = pg_class.oid AND
              pg_attribute.attnum = ANY(pg_index.indkey) AND
              indisprimary
          LOOP
            PK := PK || JSONB_BUILD_OBJECT(PRIMARY_KEYS.field_name, NEW->((PRIMARY_KEYS.field_name)::text));
          END LOOP;
          RETURN PK;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE FUNCTION
      versioning_update()
      RETURNS trigger AS $$
        DECLARE
          DATA_OLD JSONB;
          DATA_NEW JSONB;
          PK_OLD JSONB;
          PK_NEW JSONB;
        BEGIN
          DATA_OLD := TO_JSONB(OLD);
          DATA_NEW := TO_JSONB(NEW);
          PK_OLD := versioning_pk(DATA_OLD, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);
          PK_NEW := versioning_pk(DATA_NEW, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

          IF NOT jsonb_equal(PK_OLD, PK_NEW) THEN
            RAISE EXCEPTION
              'primary key is immutable for versioned tables'
              USING HINT = 'Entries should be droped and recreated instead.', ERRCODE = 'VE001';
          END IF;

          IF NOT jsonb_equal(DATA_OLD, DATA_NEW) THEN
            INSERT INTO versions
              (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
              VALUES
              (
                MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                'update'::#{Version.Event.type()},
                TG_TABLE_NAME::text,
                PK_NEW,
                DATA_NEW,
                CURRENT_SETTING('versioning.origin')::#{Version.Origin.type()},
                (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
                NOW()
              );
          END IF;

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE FUNCTION
      versioning_delete()
      RETURNS trigger AS $$
        DECLARE
          DATA JSONB;
          PK JSONB;
        BEGIN
          DATA := TO_JSONB(OLD);
          PK := versioning_pk(DATA, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

          INSERT INTO versions
            (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
            VALUES
            (
              MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
              'delete'::#{Version.Event.type()},
              TG_TABLE_NAME::text,
              PK,
              DATA,
              CURRENT_SETTING('versioning.origin')::#{Version.Origin.type()},
              (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
              NOW()
            );

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE FUNCTION
      versioning_insert()
      RETURNS trigger AS $$
        DECLARE
          DATA JSONB;
          PK JSONB;
        BEGIN
          DATA := TO_JSONB(NEW);
          PK := versioning_pk(DATA, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

          INSERT INTO versions
            (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
            VALUES
            (
              MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
              'insert'::#{Version.Event.type()},
              TG_TABLE_NAME::text,
              PK,
              DATA,
              CURRENT_SETTING('versioning.origin')::#{Version.Origin.type()},
              (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
              NOW()
            );

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    for table <- [
          :affiliations,
          :case_related_organisations,
          :cases,
          :divisions,
          :emails,
          :notes,
          :organisations,
          :people,
          :positions,
          :possible_index_submissions,
          :sedex_exports,
          :sms,
          :system_message_tenants,
          :system_messages,
          :tenants,
          :transmissions,
          :user_grants,
          :users
        ] do
      execute("""
      CREATE TRIGGER
        #{table}_versioning_insert
        AFTER INSERT ON #{table}
        FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
      """)

      execute("""
      CREATE TRIGGER
        #{table}_versioning_update
        AFTER UPDATE ON #{table}
        FOR EACH ROW EXECUTE PROCEDURE versioning_update();
      """)

      execute("""
      CREATE TRIGGER
        #{table}_versioning_delete
        AFTER DELETE ON #{table}
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """)
    end
  end
end
