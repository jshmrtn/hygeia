# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateTransmissions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:transmissions) do
      add :date, :date
      add :recipient_internal, :boolean
      add :recipient_ism_id, :string
      add :propagator_internal, :boolean
      add :propagator_ism_id, :string
      add :recipient_case_uuid, references(:cases, on_delete: :nilify_all)
      add :propagator_case_uuid, references(:cases, on_delete: :nilify_all)

      timestamps()
    end

    create index(:transmissions, [:recipient_case_uuid])
    create index(:transmissions, [:propagator_case_uuid])
  end
end
