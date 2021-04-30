# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateImports do
  use Hygeia, :migration

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row

  def change do
    Import.Type.create_type()
    Row.Status.create_type()

    create table(:imports) do
      add :type, Import.Type.type(), null: false
      add :closed_at, :utc_datetime_usec, null: true
      add :change_date, :utc_datetime_usec, null: false

      add :tenant_uuid, references(:tenants, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps()
    end

    create index(:imports, [:tenant_uuid])

    create table(:import_rows) do
      add :data, :map, null: false
      add :corrected, :map, null: true
      add :identifiers, :map, null: false
      add :status, Row.Status.type(), default: "pending"

      add :import_uuid, references(:imports, on_delete: :delete_all, type: :binary_id),
        null: false

      add :case_uuid, references(:cases, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:import_rows, [:import_uuid])
    create index(:import_rows, [:case_uuid])
    create unique_index(:import_rows, [:data])

    execute(
      """
      CREATE FUNCTION
      import_close()
      RETURNS trigger AS $$
        DECLARE
          OPEN_ROWS INTEGER;
        BEGIN
        UPDATE
          imports AS update_import
          SET closed_at = CASE
            WHEN totals.count = 0 AND update_import.closed_at IS NULL THEN NOW()
            WHEN totals.count = 0 AND update_import.closed_at IS NOT NULL THEN update_import.closed_at
            ELSE NULL
          END
          FROM (
            SELECT
              select_import.uuid AS uuid,
              COUNT(import_rows.uuid) AS count
            FROM imports select_import
            LEFT JOIN import_rows
              ON select_import.uuid = import_rows.import_uuid AND
                import_rows.status = 'pending'
            WHERE select_import.uuid IN (OLD.import_uuid, NEW.import_uuid)
            GROUP BY select_import.uuid
          ) AS totals
          WHERE totals.uuid = update_import.uuid;

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION import_close;
      """
    )

    execute(
      """
      CREATE TRIGGER
        import_rows_import_close_insert
        AFTER INSERT ON import_rows
        FOR EACH ROW EXECUTE PROCEDURE import_close()
      """,
      """
      DROP TRIGGER
        import_rows_import_close_insert
        ON import_rows
      """
    )

    execute(
      """
      CREATE TRIGGER
        import_rows_import_close_update
        AFTER UPDATE OF status, import_uuid ON import_rows
        FOR EACH ROW EXECUTE PROCEDURE import_close()
      """,
      """
      DROP TRIGGER
        import_rows_import_close_update
        ON import_rows
      """
    )

    execute(
      """
      CREATE TRIGGER
        import_rows_import_close_delete
        AFTER DELETE ON import_rows
        FOR EACH ROW EXECUTE PROCEDURE import_close()
      """,
      """
      DROP TRIGGER
        import_rows_import_close_delete
        ON import_rows
      """
    )

    for table <- [:imports, :import_rows] do
      execute(
        """
        CREATE TRIGGER
          #{table}_versioning_insert
          AFTER INSERT ON #{table}
          FOR EACH ROW EXECUTE PROCEDURE versioning_insert()
        """,
        """
        DROP TRIGGER
          #{table}_versioning_insert
          ON #{table}
        """
      )

      execute(
        """
        CREATE TRIGGER
          #{table}_versioning_update
          AFTER UPDATE ON #{table}
          FOR EACH ROW EXECUTE PROCEDURE versioning_update()
        """,
        """
        DROP TRIGGER
          #{table}_versioning_update
          ON #{table}
        """
      )

      execute(
        """
        CREATE TRIGGER
          #{table}_versioning_delete
          AFTER DELETE ON #{table}
          FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
        """,
        """
        DROP TRIGGER
          #{table}_versioning_delete
          ON #{table}
        """
      )
    end
  end
end
