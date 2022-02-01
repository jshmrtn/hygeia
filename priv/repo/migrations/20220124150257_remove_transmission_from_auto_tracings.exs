# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveTransmissionFromAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  def up do
    alter table("auto_tracings") do
      remove :transmission_uuid
    end
  end

  def down do
    alter table("auto_tracings") do
      add :transmission_uuid, references(:transmissions, on_delete: :nilify_all, type: :binary_id)
    end
  end
end
