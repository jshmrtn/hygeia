# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TransmissionInfectionPlace do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:transmissions) do
      add :infection_place, :map
    end
  end
end
