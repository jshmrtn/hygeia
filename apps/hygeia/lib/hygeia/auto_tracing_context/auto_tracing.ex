defmodule Hygeia.AutoTracingContext.AutoTracing do
  @moduledoc """
  Auto Tracing Model
  """

  use Hygeia, :model

  alias Hygeia.AutoTracingContext.AutoTracing.Employer
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias Hygeia.AutoTracingContext.AutoTracing.Transmission
  alias Hygeia.CaseContext.Case

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          current_step: Step.t() | nil,
          last_completed_step: Step.t() | nil,
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          email: String.t() | nil,
          covid_app: boolean() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          current_step: Step.t(),
          last_completed_step: Step.t(),
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          mobile: String.t() | nil,
          landline: String.t() | nil,
          email: String.t() | nil,
          covid_app: boolean() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "auto_tracings" do
    field :current_step, Step, default: :start
    field :last_completed_step, Step, default: :start
    field :covid_app, :boolean

    field :mobile, :string, virtual: true
    field :landline, :string, virtual: true
    field :email, :string, virtual: true

    embeds_one :employer, Employer, on_replace: :update
    embeds_one :transmission, Transmission, on_replace: :update

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(
          auto_tracing :: t | empty | Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Changeset.t()
  def changeset(auto_tracing, attrs \\ %{}) do
    auto_tracing
    |> cast(attrs, [
      :current_step,
      :last_completed_step,
      :case_uuid,
      :mobile,
      :landline,
      :email,
      :covid_app
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
    |> cast_embed(:employer)
    |> cast_embed(:transmission)
  end

  @spec step_available?(auto_tracing :: t, step :: Step.t()) :: boolean()
  def step_available?(auto_tracing, step) do
    steps = Step.__enum_map__()

    Enum.find_index(steps, &(&1 == step)) <=
      Enum.find_index(steps, &(&1 == auto_tracing.last_completed_step)) + 1
  end

  @spec step_completed?(auto_tracing :: t, step :: Step.t()) :: boolean()
  def step_completed?(auto_tracing, step) do
    steps = Step.__enum_map__()

    Enum.find_index(steps, &(&1 == step)) <=
      Enum.find_index(steps, &(&1 == auto_tracing.last_completed_step))
  end

  @spec first_not_completed_step?(auto_tracing :: t, step :: Step.t()) ::
          boolean()
  def first_not_completed_step?(auto_tracing, step),
    do: Step.get_next_step(auto_tracing.last_completed_step) == step

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.AutoTracingContext.AutoTracing
    alias Hygeia.CaseContext.Person
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
    def authorized?(_auto_tracing, :create, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_auto_tracing, :list, %User{} = user, %{case: case} = meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%AutoTracing{case: case}, :details, %User{} = user, meta),
      do: Resource.authorized?(case, :details, user, meta)

    def authorized?(%AutoTracing{case: case}, action, %User{} = user, meta)
        when action in [:update, :delete, :accept],
        do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_auto_tracing, action, %Person{uuid: person_uuid}, %{
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

    def authorized?(_auto_tracing, action, _user, _meta)
        when action in [:create, :details, :list, :update, :delete, :accept],
        do: false
  end
end
