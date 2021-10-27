defmodule Hygeia.AutoTracingContext.AutoTracing do
  @moduledoc """
  Auto Tracing Model
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.AutoTracingContext.AutoTracing.Flight
  alias Hygeia.AutoTracingContext.AutoTracing.Occupation
  alias Hygeia.AutoTracingContext.AutoTracing.Problem
  alias Hygeia.AutoTracingContext.AutoTracing.Propagator
  alias Hygeia.AutoTracingContext.AutoTracing.SchoolVisit
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Transmission

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          current_step: Step.t() | nil,
          last_completed_step: Step.t() | nil,
          employed: boolean() | nil,
          occupations: [Occupation.t()] | nil,
          transmission: Transmission.t() | nil,
          problems: [Problem.t()] | nil,
          solved_problems: [Problem.t()] | nil,
          unsolved_problems: [Problem.t()] | nil,
          covid_app: boolean() | nil,
          has_contact_persons: boolean() | nil,
          scholar: boolean() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          started_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          current_step: Step.t(),
          last_completed_step: Step.t() | nil,
          employed: boolean() | nil,
          occupations: [Occupation.t()] | nil,
          transmission: Transmission.t() | nil,
          problems: [Problem.t()],
          solved_problems: [Problem.t()],
          unsolved_problems: [Problem.t()],
          covid_app: boolean() | nil,
          has_contact_persons: boolean() | nil,
          scholar: boolean() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          started_at: DateTime.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type changeset_options :: %{
          optional(:covid_app_required) => boolean,
          optional(:has_contact_persons_required) => boolean,
          optional(:transmission_required) => boolean
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "auto_tracings" do
    field :current_step, Step, default: :start
    field :last_completed_step, Step
    field :covid_app, :boolean
    field :has_contact_persons, :boolean
    field :has_flown, :boolean
    field :scholar, :boolean
    field :employed, :boolean
    field :problems, {:array, Problem}, default: []
    field :solved_problems, {:array, Problem}, default: []
    field :unsolved_problems, {:array, Problem}, read_after_writes: true
    field :transmission_known, :boolean
    field :propagator_known, :boolean
    field :started_at, :utc_datetime_usec, autogenerate: {DateTime, :utc_now, []}

    embeds_many :school_visits, SchoolVisit, on_replace: :delete
    embeds_many :occupations, Occupation, on_replace: :delete
    embeds_many :flights, Flight, on_replace: :delete

    embeds_one :propagator, Propagator, on_replace: :delete

    belongs_to :transmission, Transmission,
      foreign_key: :transmission_uuid,
      references: :uuid

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(
          auto_tracing :: t | empty | Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_options :: changeset_options
        ) ::
          Changeset.t()

  def changeset(auto_tracing, attrs \\ %{}, changeset_options \\ %{})

  def changeset(auto_tracing, attrs, %{covid_app_required: true} = changeset_options) do
    auto_tracing
    |> changeset(attrs, %{changeset_options | covid_app_required: false})
    |> validate_required([:covid_app])
  end

  def changeset(auto_tracing, attrs, %{has_contact_persons_required: true} = changeset_options) do
    auto_tracing
    |> changeset(attrs, %{changeset_options | has_contact_persons_required: false})
    |> validate_required([:has_contact_persons])
  end

  def changeset(auto_tracing, attrs, %{transmission_required: true} = changeset_options) do
    auto_tracing
    |> changeset(attrs, %{changeset_options | transmission_required: false})
    |> cast_embed(:transmission, required: true)
    |> validate_transmission_required()
  end

  def changeset(auto_tracing, attrs, _changeset_options) do
    auto_tracing
    |> cast(attrs, [
      :current_step,
      :last_completed_step,
      :case_uuid,
      :covid_app,
      :scholar,
      :employed,
      :has_contact_persons,
      :problems,
      :solved_problems,
      :transmission_uuid,
      :transmission_known,
      :propagator_known,
      :started_at
    ])
    |> validate_required([:current_step, :case_uuid])
    |> cast_embed(:school_visits)
    |> cast_embed(:occupations)
    |> foreign_key_constraint(:transmission_uuid)
  end

  defp validate_transmission_required(changeset) do
    changeset
    |> fetch_field!(:transmission)
    |> case do
      %Transmission{} = transmission ->
        transmission
        |> Transmission.changeset(%{})
        |> case do
          %Ecto.Changeset{valid?: true} ->
            changeset

          %Ecto.Changeset{valid?: false} ->
            add_error(changeset, :transmission, dgettext("errors", "is invalid"))
        end

      nil ->
        add_error(changeset, :transmission, dgettext("errors", "is invalid"))
    end
  end

  @spec has_problem?(t, problem :: Problem.t()) :: boolean
  def has_problem?(%__MODULE__{problems: problems}, problem), do: problem in problems

  @spec step_available?(auto_tracing :: t, step :: Step.t()) :: boolean()
  def step_available?(%__MODULE__{} = auto_tracing, step) do
    steps = Step.__enum_map__()

    step_index = Enum.find_index(steps, &(&1 == step))

    if has_problem?(auto_tracing, :unmanaged_tenant) do
      step_index <= Enum.find_index(steps, &(&1 == :address))
    else
      case auto_tracing.last_completed_step do
        nil ->
          step_index <= 0

        last_completed_step ->
          step_index <= Enum.find_index(steps, &(&1 == last_completed_step)) + 1
      end
    end
  end

  @spec step_completed?(auto_tracing :: t, step :: Step.t()) :: boolean()
  def step_completed?(auto_tracing, step) do
    case auto_tracing.last_completed_step do
      nil ->
        false

      _other ->
        steps = Step.__enum_map__()

        Enum.find_index(steps, &(&1 == step)) <=
          Enum.find_index(steps, &(&1 == auto_tracing.last_completed_step))
    end
  end

  @spec first_not_completed_step?(auto_tracing :: t, step :: Step.t()) ::
          boolean()
  def first_not_completed_step?(auto_tracing, step) do
    case auto_tracing.last_completed_step do
      nil -> :start
      _other -> Step.get_next_step(auto_tracing.last_completed_step) == step
    end
  end

  @spec completed?(auto_tracing :: t) :: boolean
  def completed?(%__MODULE__{} = auto_tracing),
    do: step_completed?(auto_tracing, :contact_persons)

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.AutoTracingContext.AutoTracing
    alias Hygeia.CaseContext.Person
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: AutoTracing.t()) :: AutoTracing.t()
    def preload(resource), do: Repo.preload(resource, case: [tenant: []])

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
        when action in [:update, :delete, :accept, :resolve_problems],
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
        when action in [:create, :details, :list, :update, :delete, :accept, :resolve_problems],
        do: false
  end
end
