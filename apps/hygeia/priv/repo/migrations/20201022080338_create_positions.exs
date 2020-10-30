# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePositions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:positions) do
      add :position, :string, null: false
      add :person_uuid, references(:people), null: false
      add :organisation_uuid, references(:organisations), null: false

      timestamps()
    end

    create index(:positions, [:person_uuid])
    create index(:positions, [:organisation_uuid])
  end
end
