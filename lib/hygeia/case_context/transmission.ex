defmodule Hygeia.CaseContext.Transmission do
  @moduledoc """
  Case Transmission Schema

  A transmission has to point to at least a propagator or a recipient case

  If one of the two sides is managed by an entity outside of this system, an ISM id can be specified instead.
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          date: Date.t() | nil,
          comment: String.t() | nil,
          propagator_internal: boolean,
          propagator_ism_id: String.t() | nil,
          propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          propagator_case_uuid: Ecto.UUID.t() | nil,
          recipient_internal: boolean,
          recipient_ism_id: String.t() | nil,
          recipient_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          recipient_case_uuid: Ecto.UUID.t() | nil,
          infection_place: InfectionPlace.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          date: Date.t() | nil,
          comment: String.t() | nil,
          propagator_internal: boolean | nil,
          propagator_ism_id: String.t() | nil,
          propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          propagator_case_uuid: Ecto.UUID.t() | nil,
          propagator: Ecto.Schema.has_one(Person.t()) | nil,
          recipient_internal: boolean | nil,
          recipient_ism_id: String.t() | nil,
          recipient_case: Ecto.Schema.belongs_to(Case.t()) | nil,
          recipient_case_uuid: Ecto.UUID.t() | nil,
          recipient: Ecto.Schema.has_one(Person.t()) | nil,
          infection_place: InfectionPlace.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_params :: %{optional(:place_type_required) => boolean()}

  @derive {Phoenix.Param, key: :uuid}

  schema "transmissions" do
    field :date, :date
    field :comment, :string
    field :propagator_ism_id, :string
    field :propagator_internal, :boolean
    field :recipient_ism_id, :string
    field :recipient_internal, :boolean

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid
    has_one :propagator, through: [:propagator_case, :person]
    belongs_to :recipient_case, Case, references: :uuid, foreign_key: :recipient_case_uuid
    has_one :recipient, through: [:recipient_case, :person]

    embeds_one :infection_place, InfectionPlace, on_replace: :update

    timestamps()
  end

  @spec changeset(
          transmission :: t | empty | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: changeset_params
        ) ::
          Ecto.Changeset.t(t)
  def changeset(transmission, attrs \\ %{}, changeset_params \\ %{})

  def changeset(transmission, attrs, %{place_type_required: true} = changeset_params) do
    transmission
    |> changeset(attrs, %{changeset_params | place_type_required: false})
    |> cast_embed(:infection_place,
      with: &InfectionPlace.changeset(&1, &2, %{type_required: true}),
      required: true
    )
  end

  def changeset(transmission, attrs, _changeset_params) do
    transmission
    |> cast(attrs, [
      :uuid,
      :date,
      :comment,
      :recipient_internal,
      :recipient_ism_id,
      :propagator_case_uuid,
      :propagator_internal,
      :propagator_ism_id,
      :recipient_case_uuid
    ])
    |> cast_embed(:infection_place)
    |> validate_required([:date])
    |> validate_past_date(:date)
    |> validate_case(:propagator_internal, :propagator_ism_id, :propagator_case_uuid)
    |> validate_case(:recipient_internal, :recipient_ism_id, :recipient_case_uuid)
    |> validate_propagator_or_recipient_required()
  end

  @spec validate_case(
          changeset :: Ecto.Changeset.t(entity),
          internal_key :: atom,
          ism_id_key :: atom,
          case_relation_key :: atom
        ) :: Ecto.Changeset.t(entity)
        when entity: term
  def validate_case(changeset, internal_key, ism_id_key, case_relation_key) do
    changeset
    |> fetch_field!(internal_key)
    |> case do
      nil ->
        changeset
        |> put_change(ism_id_key, nil)
        |> put_change(case_relation_key, nil)

      true ->
        changeset
        |> put_change(ism_id_key, nil)
        |> validate_required([case_relation_key])

      false ->
        changeset
        |> validate_required([ism_id_key])
        |> put_change(case_relation_key, nil)
    end
  end

  defp validate_propagator_or_recipient_required(changeset) do
    changeset
    |> get_field(:propagator_case_uuid)
    |> case do
      nil -> validate_required(changeset, [:recipient_case_uuid])
      uuid when is_binary(uuid) -> validate_required(changeset, [:propagator_case_uuid])
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.CaseContext.Transmission
    alias Hygeia.Repo
    alias Hygeia.UserContext.User

    @spec preload(resource :: Transmission.t()) :: Transmission.t()
    def preload(resource), do: Repo.preload(resource, propagator_case: [], recipient_case: [])

    @spec authorized?(
            resource :: Transmission.t(),
            action :: :create | :details | :list | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(
          %Transmission{propagator_case: propagator_case, recipient_case: recipient_case},
          action,
          user,
          meta
        )
        when action in [:details, :update, :delete, :versioning] do
      [propagator_case, recipient_case]
      |> Enum.reject(&is_nil/1)
      |> Enum.any?(&Resource.authorized?(&1, action, user, meta))
    end

    def authorized?(_module, :deleted_versioning, user, _meta),
      do: User.has_role?(user, :admin, :any)

    def authorized?(_transmission, :create, :anonymous, _meta), do: false
    def authorized?(_transmission, :create, %Person{}, _meta), do: false

    def authorized?(_transmission, :create, user, _meta),
      do: Enum.any?([:tracer, :supervisor, :admin], &User.has_role?(user, &1, :any))
  end
end
