# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.ModifyTransmissionInAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table("auto_tracings") do
      add :propagator_known, :boolean
      add :transmission_known, :boolean
      add :propagator, :map
      add :transmission_uuid, references(:transmissions, on_delete: :nilify_all, type: :binary_id)

      remove :transmission
    end
  end
end
