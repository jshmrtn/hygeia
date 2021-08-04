defmodule Hygeia.AutoTracingContext.AutoTracing do
  @moduledoc """
  Auto Tracing Model
  """

  use Hygeia, :model

  import EctoEnum
  import HygeiaGettext

  alias Hygeia.AutoTracingContext.Employer
  alias Hygeia.AutoTracingContext.Transmission
  alias Hygeia.CaseContext.Case

  defenum(Step, :auto_tracing_step, [
    :start,
    :address,
    :contact_methods,
    :employer,
    :vaccination,
    :covid_app,
    :clinical,
    :transmission,
    :finished
  ])

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          current_step: Step.t() | nil,
          last_completed_step: Step.t() | nil,
          closed: boolean | nil,
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          email: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          current_step: Step.t(),
          last_completed_step: Step.t(),
          closed: boolean,
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          email: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "auto_tracings" do
    field :closed, :boolean
    field :current_step, Step
    field :last_completed_step, Step

    field :mobile, :string, virtual: true
    field :landline, :string, virtual: true
    field :email, :string, virtual: true

    embeds_one :employer, Employer
    embeds_one :transmission, Transmission

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(auto_tracing :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(auto_tracing, attrs \\ %{}) do
    auto_tracing
    |> cast(attrs, [
      :closed,
      :current_step,
      :last_completed_step,
      :case_uuid,
      :mobile,
      :landline,
      :email
    ])
    |> validate_required([:current_step, :last_completed_step, :case_uuid])
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
    |> validate_email(:email)
    # |> validate_contact_methods()
    |> cast_embed(:employer)
    |> cast_embed(:transmission)
  end

  # defp validate_contact_methods(changeset) do
  #   if get_field(changeset, :current_step) == :contact do
  #     with nil <- get_field(changeset, :mobile),
  #          nil <- get_field(changeset, :email) do
  #       validate_required(changeset, [:landline],
  #         message: dgettext("errors", "at least one contact method must be provided")
  #       )
  #     end
  #   else
  #     changeset
  #   end
  # end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.CaseContext.Person
    alias Hygeia.AutoTracingContext.AutoTracing
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: AutoTracing.t()) :: AutoTracing.t()
    def preload(resource), do: Repo.preload(resource, :case)

    @spec authorized?(
            resource :: AutoTracing.t(),
            action :: :create | :details | :list | :update | :delete | :accept,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_possible_index_submission, :create, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_possible_index_submission, :list, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%AutoTracing{case: case}, :details, %User{} = user, meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%AutoTracing{case: case}, action, %User{} = user, meta)
        when action in [:update, :delete, :accept],
        do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_possible_index_submission, action, %Person{uuid: person_uuid}, %{
          case: %Case{person_uuid: person_uuid}
        })
        when action in [:create, :list],
        do: true

    def authorized?(
          %AutoTracing{case: %Case{person_uuid: person_uuid}},
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
