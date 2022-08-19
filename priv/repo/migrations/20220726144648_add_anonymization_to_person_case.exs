# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddAnonymizationToPersonCase do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:people) do
      add :anonymized, :boolean, default: false
      add :anonymization_date, :date
      add :reidentification_date, :date
    end

    alter table(:cases) do
      add :anonymized, :boolean, default: false
      add :anonymization_date, :date
      add :reidentification_date, :date
    end
  end
end
