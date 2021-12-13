# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePoliticalTerritories do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.EctoType.Country

  def change do
    create table(:political_territories) do
      add :country, Country.type(), null: false
      add :risk_related, :boolean, null: false

      timestamps()
    end

    create unique_index(:political_territories, [:country])
  end
end
