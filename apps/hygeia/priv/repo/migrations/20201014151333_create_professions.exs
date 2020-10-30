# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateProfessions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:professions) do
      add :name, :string

      timestamps()
    end
  end
end
