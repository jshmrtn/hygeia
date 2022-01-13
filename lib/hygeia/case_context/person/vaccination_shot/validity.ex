defmodule Hygeia.CaseContext.Person.VaccinationShot.Validity do
  @moduledoc """
  Model for Vaccination Shot Validity
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.VaccinationShot

  @type t :: %__MODULE__{
          vaccination_shot: Ecto.Schema.belongs_to(VaccinationShot.t()),
          vaccination_shot_uuid: Ecto.UUID.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          person_uuid: Ecto.UUID.t(),
          range: Hygeia.EctoType.DateRange.t()
        }

  @primary_key false
  schema "vaccination_shot_validity" do
    field :range, Hygeia.EctoType.DateRange

    belongs_to :person, Person, foreign_key: :person_uuid, references: :uuid

    belongs_to :vaccination_shot, VaccinationShot,
      foreign_key: :vaccination_shot_uuid,
      references: :uuid
  end
end
