# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddFlightsToAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    alter table(:auto_tracings) do
      add :has_flown, :boolean
      add :flights, {:array, :map}
    end
  end
end
