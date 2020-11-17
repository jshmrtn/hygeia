# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateInfectionPlaceTypes do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:infection_place_types) do
      add :name, :string, null: false

      timestamps()
    end
  end
end
