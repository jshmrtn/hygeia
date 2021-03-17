# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.SedexExportUnique do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    DELETE
      FROM sedex_exports a
      USING sedex_exports b
      WHERE a.inserted_at > b.inserted_at
        AND a.tenant_uuid = b.tenant_uuid
        AND a.scheduling_date = b.scheduling_date
    """)

    create unique_index(:sedex_exports, [:tenant_uuid, :scheduling_date])
  end
end
