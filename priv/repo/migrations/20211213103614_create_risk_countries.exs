# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateRiskCountries do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.EctoType.Country

  def change do
    create table(:risk_countries) do
      add :country, Country.type(), null: false
    end

    create unique_index(:risk_countries, [:country])

    # TODO Create migration query
    rename table(:auto_tracings), :has_travelled, to: :has_travelled_in_risk_country

    alter table(:auto_tracings) do
      remove :travel
      add :travels, {:array, :map}
    end
  end
end
