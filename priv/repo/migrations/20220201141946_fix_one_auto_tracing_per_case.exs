# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FixOneAutoTracingPerCase do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    execute(
      """
        DELETE FROM auto_tracings
        WHERE uuid IN (
          WITH sorted_auto_tracings AS(
            SELECT uuid, updated_at, ROW_NUMBER() OVER (PARTITION BY case_uuid ORDER BY updated_at DESC) AS row_num
            FROM auto_tracings
            )
          SELECT uuid FROM sorted_auto_tracings
          WHERE row_num > 1
          )
      """,
      &noop/0
    )

    create unique_index(:auto_tracings, [:case_uuid])
  end
end
