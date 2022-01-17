defmodule Hygeia.CaseContext.Person.VaccinationShot do
  @moduledoc """
  Model for Vaccination Session
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType
  alias Hygeia.CaseContext.Person.VaccinationShot.Validity

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

    has_one :validity, Validity

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
    |> fill_uuid
    |> validate_required([:date, :vaccine_type])
    |> validate_past_date(:date)
    |> validate_type_other()
    |> unique_constraint(:date, name: :vaccination_shots_person_uuid_date_index)
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:vaccine_type)
    |> case do
      nil -> changeset
      :other -> validate_required(changeset, [:vaccine_type_other])
      _defined -> put_change(changeset, :vaccine_type_other, nil)
    end
  end
end
