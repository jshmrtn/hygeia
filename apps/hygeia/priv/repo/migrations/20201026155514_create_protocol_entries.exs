defmodule Hygeia.Repo.Migrations.CreateProtocolEntries do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:protocol_entries) do
      add :entry, :map
      add :case_uuid, references(:cases, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:protocol_entries, [:case_uuid])
    create index(:protocol_entries, [:inserted_at])
  end
end
