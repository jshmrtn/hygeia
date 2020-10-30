# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Repo.Migrations.AddVersions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:versions, primary_key: false) do
      add :id, :bigserial, null: false, primary_key: true
      add :event, :string, null: false, size: 10
      add :item_type, :string, null: false
      add :item_id, :uuid
      add :item_changes, :map, null: false
      add :originator_id, references(:users), null: true
      add :origin, :string, size: 50
      add :meta, :map

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create index(:versions, [:originator_id])
    create index(:versions, [:item_id, :item_type])
    create index(:versions, [:event, :item_type])
    create index(:versions, [:item_type, :inserted_at])
  end
end
