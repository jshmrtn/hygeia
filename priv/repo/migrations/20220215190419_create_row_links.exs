# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateRowLinks do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    create table(:row_links, primary_key: false) do
      add :import_uuid, references(:imports, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :row_uuid, references(:import_rows, on_delete: :delete_all),
        null: false,
        primary_key: true

      timestamps()
    end

    execute(
      """
      INSERT INTO row_links (import_uuid, row_uuid, inserted_at, updated_at)
        SELECT
          import.uuid,
          row.uuid,
          NOW(),
          NOW()
        FROM imports as import
        INNER JOIN import_rows as row
        ON row.import_uuid = import.uuid
      """,
      &noop/0
    )

    execute(
      """
      CREATE FUNCTION
        delete_rows_with_no_import_link()
        RETURNS trigger AS $$
          BEGIN
            IF  NOT EXISTS (SELECT 1 FROM row_links WHERE row_uuid = OLD.row_uuid) THEN
              DELETE FROM import_rows WHERE uuid = OLD.row_uuid;
            END IF;

            RETURN OLD;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION delete_rows_with_no_import_link;
      """
    )

    execute(
      """
      CREATE TRIGGER
        delete_orphaned_rows
        AFTER DELETE ON row_links
        FOR EACH STATEMENT EXECUTE PROCEDURE delete_rows_with_no_import_link();
      """,
      """
      DROP TRIGGER delete_orphaned_rows ON row_links;
      """
    )
  end
end
