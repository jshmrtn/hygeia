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
          uuid: Ecto.UUID.t() | nil,
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t() | nil,
          transmission_date: Date.t() | nil,
          email: String.t() | nil,
          comment: String.t() | nil,
          infection_place: InfectionPlace.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          employer: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          first_name: String.t(),
          last_name: String.t(),
          sex: Sex.t() | nil,
          birth_date: Date.t() | nil,
          address: Address.t(),
          email: String.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          transmission_date: Date.t() | nil,
          comment: String.t() | nil,
          infection_place: InfectionPlace.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          employer: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
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
    field :employer, :string
    field :comment, :string

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
      :transmission_date,
      :employer,
      :comment
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
         nil <- get_field(changeset, :email) do
      validate_required(changeset, [:mobile],
        message: dgettext("errors", "at least one contact method must be provided")
      )
    else
      _other_value -> changeset
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.CaseContext.Person
    alias Hygeia.CaseContext.PossibleIndexSubmission
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: PossibleIndexSubmission.t()) :: PossibleIndexSubmission.t()
    def preload(resource), do: Repo.preload(resource, :case)

    @spec authorized?(
            resource :: PossibleIndexSubmission.t(),
            action :: :create | :details | :list | :update | :delete | :accept,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_possible_index_submission, :create, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_possible_index_submission, :list, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%PossibleIndexSubmission{case: case}, :details, %User{} = user, meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%PossibleIndexSubmission{case: case}, action, %User{} = user, meta)
        when action in [:update, :delete, :accept],
        do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_possible_index_submission, action, %Person{uuid: person_uuid}, %{
          case: %Case{person_uuid: person_uuid}
        })
        when action in [:create, :list],
        do: true

    def authorized?(
          %PossibleIndexSubmission{case: %Case{person_uuid: person_uuid}},
          action,
          %Person{uuid: person_uuid},
          _meta
        )
        when action in [:details, :update, :delete],
        do: true

    def authorized?(_possible_index_submission, action, _user, _meta)
        when action in [:create, :details, :list, :update, :delete, :accept],
        do: false
  end
end
