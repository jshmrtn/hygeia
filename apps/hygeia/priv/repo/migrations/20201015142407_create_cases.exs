# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateCases do
  @moduledoc false

  use Hygeia, :migration

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def change do
    create table(:cases) do
      add :human_readable_id, :string
      add :external_references, {:array, :map}
      add :complexity, :string
      add :clinical, :map
      add :monitoring, :map
      add :hospitalizations, {:array, :map}
      add :phases, {:array, :map}
      add :status, :string, null: false
      add :tracer_uuid, references(:users), null: false
      add :supervisor_uuid, references(:users), null: false
      add :person_uuid, references(:people), null: false
      add :tenant_uuid, references(:tenants), null: false

      timestamps()
    end

    create index(:cases, [:tracer_uuid])
    create index(:cases, [:supervisor_uuid])
    create index(:cases, [:person_uuid])
    create index(:cases, [:tenant_uuid])
    create index(:cases, [:external_references], using: :gin)
    create index(:cases, [:phases], using: :gin)
  end
end
