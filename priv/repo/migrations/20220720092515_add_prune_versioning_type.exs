# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddPruneVersioningType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.VersionContext.Version

  @disable_ddl_transaction true

  def up do
    # make auto_tracings and visits triggers same name as other tables (table_name_versioning_...)
    execute("""
    ALTER TRIGGER auto_tracing_versioning_insert ON auto_tracings RENAME TO auto_tracings_versioning_insert;
    """)

    execute("""
    ALTER TRIGGER auto_tracing_versioning_update ON auto_tracings RENAME TO auto_tracings_versioning_update;
    """)

    execute("""
    ALTER TRIGGER auto_tracing_versioning_delete ON auto_tracings RENAME TO auto_tracings_versioning_delete;
    """)

    execute("""
    ALTER TRIGGER visit_versioning_insert ON visits RENAME TO visits_versioning_insert;
    """)

    execute("""
    ALTER TRIGGER visit_versioning_update ON visits RENAME TO visits_versioning_update;
    """)

    execute("""
    ALTER TRIGGER visit_versioning_delete ON visits RENAME TO visits_versioning_delete;
    """)

    execute("""
    ALTER TYPE
      #{Version.Origin.type()}
      ADD VALUE IF NOT EXISTS 'data_pruning';
    """)

    for table <- [
          :affiliations,
          :auto_tracings,
          :cases,
          :divisions,
          :emails,
          :hospitalizations,
          :import_rows,
          :imports,
          :notes,
          :notifications,
          :organisations,
          :people,
          :positions,
          :possible_index_submissions,
          :sedex_exports,
          :sms,
          :system_message_tenants,
          :system_messages,
          :tenants,
          :tests,
          :transmissions,
          :user_grants,
          :users,
          :vaccination_shots,
          :visits
        ] do
      execute("""
      DROP TRIGGER
        #{table}_versioning_delete
        ON #{table}
      """)
    end

    execute("""
    DROP FUNCTION versioning_delete;
    """)

    execute("""
    CREATE FUNCTION
      versioning_delete()
      RETURNS trigger AS $$
        DECLARE
          DATA JSONB;
          PK JSONB;
        BEGIN
          IF CURRENT_SETTING('versioning.origin') <> 'data_pruning' THEN
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
          END IF;

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    for table <- [
          :affiliations,
          :auto_tracings,
          :cases,
          :divisions,
          :emails,
          :hospitalizations,
          :import_rows,
          :imports,
          :notes,
          :notifications,
          :organisations,
          :people,
          :positions,
          :possible_index_submissions,
          :sedex_exports,
          :sms,
          :system_message_tenants,
          :system_messages,
          :tenants,
          :tests,
          :transmissions,
          :user_grants,
          :users,
          :vaccination_shots,
          :visits
        ] do
      execute("""
      CREATE TRIGGER
        #{table}_versioning_delete
        AFTER DELETE ON #{table}
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """)
    end
  end
end
