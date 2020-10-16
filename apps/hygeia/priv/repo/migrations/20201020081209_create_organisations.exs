defmodule Hygeia.Repo.Migrations.CreateOrganisations do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:organisations) do
      add :name, :string, null: false
      add :address, :map
      add :notes, :string

      timestamps()
    end
  end
end
