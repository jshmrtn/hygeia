# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateNotifications do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:notifications) do
      add :body, :map
      add :read, :boolean, default: false, null: false
      add :notified, :boolean, default: false, null: false
      add :user_uuid, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notifications, [:user_uuid])
    create index(:notifications, [:read])
    create index(:notifications, [:notified])
    create index(:notifications, [:user_uuid, :read, :notified])

    execute(
      """
      CREATE TRIGGER
        notifications_versioning_insert
        AFTER INSERT ON notifications
        FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
      """,
      """
      DROP TRIGGER notifications_versioning_insert ON notifications;
      """
    )

    execute(
      """
      CREATE TRIGGER
        notifications_versioning_update
        AFTER UPDATE ON notifications
        FOR EACH ROW EXECUTE PROCEDURE versioning_update();
      """,
      """
      DROP TRIGGER notifications_versioning_update ON notifications;
      """
    )

    execute(
      """
      CREATE TRIGGER
        notifications_versioning_delete
        AFTER DELETE ON notifications
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """,
      """
      DROP TRIGGER notifications_versioning_delete ON notifications;
      """
    )

    execute(
      """
      CREATE FUNCTION
        case_assignee_notification()
        RETURNS trigger AS $$
          BEGIN
            IF (OLD.tracer_uuid <> NEW.tracer_uuid OR OLD IS NULL) AND NOT NEW.tracer_uuid IS NULL AND (NEW.tracer_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
              INSERT INTO notifications
                (uuid, body, user_uuid, inserted_at, updated_at) VALUES
                (
                  MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                  JSONB_BUILD_OBJECT('__type__', 'case_assignee', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.uuid),
                  NEW.tracer_uuid,
                  NOW(),
                  NOW()
                );
            END IF;

            IF (OLD.supervisor_uuid <> NEW.supervisor_uuid OR OLD IS NULL) AND NOT NEW.supervisor_uuid IS NULL AND (NEW.supervisor_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
              INSERT INTO notifications
                (uuid, body, user_uuid, inserted_at, updated_at) VALUES
                (
                  MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                  JSONB_BUILD_OBJECT('__type__', 'case_assignee', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.uuid),
                  NEW.supervisor_uuid,
                  NOW(),
                  NOW()
                );
            END IF;

            RETURN NEW;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION case_assignee_notification;
      """
    )

    execute(
      """
      CREATE TRIGGER
        cases_assignee_changed
        AFTER INSERT OR UPDATE ON cases
        FOR EACH ROW EXECUTE PROCEDURE case_assignee_notification();
      """,
      """
      DROP TRIGGER cases_assignee_changed ON cases;
      """
    )

    execute(
      """
      CREATE FUNCTION
        email_send_failed()
        RETURNS trigger AS $$
          DECLARE
            AFFECTED_TRACER_UUID UUID;
          BEGIN
            IF (OLD.status <> NEW.status OR OLD IS NULL) AND NEW.status IN ('retries_exceeded', 'permanent_failure') THEN
              SELECT tracer_uuid INTO AFFECTED_TRACER_UUID FROM cases WHERE uuid = NEW.case_uuid;

              IF NOT AFFECTED_TRACER_UUID IS NULL THEN
                INSERT INTO notifications
                  (uuid, body, user_uuid, inserted_at, updated_at) VALUES
                  (
                    MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                    JSONB_BUILD_OBJECT('__type__', 'email_send_failed', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.case_uuid, 'email_uuid', NEW.uuid),
                    AFFECTED_TRACER_UUID,
                    NOW(),
                    NOW()
                  );
              END IF;
            END IF;

            RETURN NEW;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION email_send_failed;
      """
    )

    execute(
      """
      CREATE TRIGGER
        email_status_changed
        AFTER INSERT OR UPDATE ON emails
        FOR EACH ROW EXECUTE PROCEDURE email_send_failed();
      """,
      """
      DROP TRIGGER email_status_changed ON emails;
      """
    )

    execute(
      """
      CREATE FUNCTION
        notification_created()
        RETURNS trigger AS $$
          BEGIN
            PERFORM pg_notify(
              'notification_created',
              ROW_TO_JSON(NEW)::text
            );

            RETURN NEW;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION notification_created;
      """
    )

    execute(
      """
      CREATE TRIGGER
        notification_created
        AFTER INSERT ON notifications
        FOR EACH ROW EXECUTE PROCEDURE notification_created();
      """,
      """
      DROP TRIGGER notification_created ON notifications;
      """
    )
  end
end
