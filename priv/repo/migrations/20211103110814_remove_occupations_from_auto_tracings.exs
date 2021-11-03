# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveOccupationsFromAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:auto_tracings) do
      remove :occupations
    end
  end
end
