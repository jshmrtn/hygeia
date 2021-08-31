defmodule Hygeia.Repo.Migrations.ModifyTransmissionInAutoTracings do
  use Ecto.Migration

  def change do
    alter table("auto_tracings") do
      add :propagator_known, :boolean
      add :transmission_known, :boolean
      add :propagator, :map
      add :transmission_uuid, references(:transmissions, on_delete: :delete_all, type: :binary_id)

      remove :transmission
    end
  end
end
