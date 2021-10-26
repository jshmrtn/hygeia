defmodule Hygeia.CaseContext.PrematureRelease do
  @moduledoc """
  Premature Release Model
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PrematureRelease.Reason
  alias Hygeia.TenantContext.Tenant

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          reason: Reason.t() | nil,
          case_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          person: Ecto.Schema.has_one(Person.t()) | nil,
          phase_uuid: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          reason: Reason.t(),
          case_uuid: Ecto.UUID.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          person: Ecto.Schema.has_one(Person.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          phase_uuid: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "premature_releases" do
    field :reason, Reason
    field :phase_uuid, :binary_id
    field :has_documentation, :boolean, virtual: true, default: false
    field :truthful, :boolean, virtual: true, default: false

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
    has_one :tenant, through: [:case, :tenant]
    has_one :person, through: [:case, :person]

    timestamps()
  end

  @doc false
  @spec changeset(
          premature_release :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(t)
  def changeset(premature_release, attrs) do
    premature_release
    |> cast(attrs, [:reason, :has_documentation, :truthful])
    |> validate_required([:reason])
  end

  @spec create_changeset(
          premature_release :: empty | t | Ecto.Changeset.t(t | empty),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(t)
  def create_changeset(premature_release, attrs) do
    premature_release
    |> changeset(attrs)
    |> validate_required([:has_documentation, :truthful])
    |> validate_acceptance(:has_documentation)
    |> validate_acceptance(:truthful)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.Authorization.Resource
    alias Hygeia.CaseContext.Person
    alias Hygeia.CaseContext.PrematureRelease
    alias Hygeia.Repo
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Case.t()) :: Case.t()
    def preload(resource), do: Repo.preload(resource, tenant: [], person: [])

    @spec authorized?(
            resource :: PrematureRelease.t(),
            action ::
              :details | :create | :list | :update | :delete | :versioning | :deleted_versioning,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_premature_release, action, :anonymous, _meta)
        when action in [
               :list,
               :create,
               :details,
               :update,
               :delete,
               :versioning,
               :deleted_versioning
             ],
        do: false

    def authorized?(%PrematureRelease{tenant: tenant}, action, %User{} = user, _meta)
        when action in [:details, :update, :delete, :versioning],
        do:
          Enum.any?(
            [:tracer, :supervisor, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, tenant)
          )

    def authorized?(_premature_release, action, %User{} = user, %{case: case} = meta)
        when action in [:list, :create],
        do: Resource.authorized?(case, :update, user, meta)

    def authorized?(_module, :deleted_versioning, user, _meta),
      do: User.has_role?(user, :admin, :any)

    def authorized?(
          _premature_release,
          action,
          %Person{uuid: person_uuid},
          %{case: %Case{person_uuid: person_uuid}}
        )
        when action in [:list, :create],
        do: true

    def authorized?(_premature_release, action, %Person{}, %{case: %Case{}})
        when action in [:list, :create],
        do: false

    def authorized?(
          %PrematureRelease{tenant: %Person{uuid: person_uuid}},
          action,
          %Person{uuid: person_uuid},
          _meta
        )
        when action in [:details, :update, :delete],
        do: true

    def authorized?(%PrematureRelease{tenant: %Person{}}, action, %Person{}, _meta)
        when action in [:details, :update, :delete],
        do: false

    def authorized?(_premature_release, action, %Person{}, _meta)
        when action in [:versioning, :deleted_versioning],
        do: false
  end
end
