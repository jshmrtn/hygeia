# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveSchoolVisitsFromAutoTracings do
  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    alter table(:auto_tracings) do
      remove :school_visits
    end
  end
end
