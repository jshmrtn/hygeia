# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingHasContactPersons do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:auto_tracings) do
      add :has_contact_persons, :boolean
    end
  end
end
