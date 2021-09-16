# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddVisitedSchoolsToAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    alter table(:auto_tracings) do
      add :school_visits, {:array, :map}
    end
  end
end
