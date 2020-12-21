defmodule Hygeia.CaseContext.PossibleIndexSubmission do
  @moduledoc """
  Model for Possible Index Submission
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person.Sex
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t() | nil,
          transmission_date: Date.t() | nil,
          email: String.t() | nil,
          infection_place: InfectionPlace.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t(),
          email: String.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          transmission_date: Date.t() | nil,
          infection_place: InfectionPlace.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "possible_index_submissions" do
    field :birth_date, :date
    field :email, :string
    field :first_name, :string
    field :landline, :string
    field :last_name, :string
    field :mobile, :string
    field :sex, Sex
    field :transmission_date, :date

    embeds_one :address, Address, on_replace: :update
    embeds_one :infection_place, InfectionPlace, on_replace: :update

    field :suspected_duplicates_uuid, {:array, :binary_id}, virtual: true, default: []

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(possible_index_submission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(possible_index_submission, attrs) do
    possible_index_submission
    |> cast(attrs, [
      :uuid,
      :first_name,
      :last_name,
      :email,
      :mobile,
      :landline,
      :sex,
      :birth_date,
      :transmission_date
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :transmission_date
    ])
    |> cast_embed(:address)
    |> cast_embed(:infection_place, required: true)
    |> validate_email(:email)
    |> validate_and_normalize_phone(:mobile, fn
      :mobile -> :ok
      :fixed_line_or_mobile -> :ok
      :personal_number -> :ok
      :unknown -> :ok
      _other -> {:error, "not a mobile number"}
    end)
    |> validate_and_normalize_phone(:landline, fn
      :fixed_line -> :ok
      :fixed_line_or_mobile -> :ok
      :voip -> :ok
      :personal_number -> :ok
      :uan -> :ok
      :unknown -> :ok
      _other -> {:error, "not a landline number"}
    end)
    |> validate_contact_methods()
    |> detect_name_duplicates
    |> detect_duplicates(:mobile)
    |> detect_duplicates(:landline)
    |> detect_duplicates(:email)
  end

  defp validate_contact_methods(changeset) do
    with nil <- get_field(changeset, :mobile),
         nil <- get_field(changeset, :email),
         nil <- get_field(changeset, :landline) do
      validate_required(changeset, [:mobile],
        message: dgettext("errors", "at least one contact method must be provided")
      )
    else
      _other_value -> changeset
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.PossibleIndexSubmission
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: PossibleIndexSubmission.t(),
            action :: :create | :details | :list | :update | :delete | :accept,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_possible_index_submission, action, _user, _meta)
        when action in [:create, :details, :list, :update, :delete],
        do: true
  end
end
