defmodule Hygeia.CaseContext.Person.VaccinationShot do
  @moduledoc """
  Model for Vaccination Session
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          vaccine_type: VaccineType.t() | nil,
          vaccine_type_other: String.t() | nil,
          date: Date.t() | nil
        }

  @type t :: empty

  @type changeset_options :: %{
          optional(:required) => boolean,
          optional(:initial_nil_jab_date_count) => integer
        }

  schema "vaccination_shots" do
    field :vaccine_type, VaccineType
    field :vaccine_type_other, :string
    field :date, :date
    belongs_to :person, Person, foreign_key: :person_uuid, references: :uuid

    timestamps()
  end

  @doc false
  @spec changeset(
          vaccination_shot :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Changeset.t()
  def changeset(vaccination_shot, attrs \\ %{})

  def changeset(vaccination_shot, attrs) do
    vaccination_shot
    |> cast(attrs, [:uuid, :vaccine_type, :vaccine_type_other, :date])
    |> validate_required([:vaccine_type, :date])
    |> fill_uuid
    |> validate_past_date(:date)
  end
end
