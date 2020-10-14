defmodule Hygeia.Repo.Migrations.CreateTenants do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:tenants) do
      add :name, :string

      timestamps()
    end
  end
end
