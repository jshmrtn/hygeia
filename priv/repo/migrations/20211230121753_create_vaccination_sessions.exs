# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateVaccinationShots do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType

  def change do
    alter table(:people) do
      add :is_vaccinated, :boolean
    end

    VaccineType.create_type()

    create table(:vaccination_shots) do
      add :vaccine_type, VaccineType.type()
      add :other_vaccine_name, :string
      add :date, :date
      add :person_uuid, references(:people, on_delete: :nothing), null: false

      timestamps()
    end
  end
end
