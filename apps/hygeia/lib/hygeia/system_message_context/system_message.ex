defmodule Hygeia.SystemMessageContext.SystemMessage do
  @moduledoc """
  Model for System Message
  """

  use Hygeia, :model

  import Ecto.Query

  alias Hygeia.EctoType.LocalizedNaiveDatetime
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.Grant.Role

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          text: String.t() | nil,
          start_date: LocalizedNaiveDatetime.t() | nil,
          end_date: LocalizedNaiveDatetime.t() | nil,
          related_tenants: Ecto.Schema.many_to_many(Tenant.t()) | nil,
          roles: [Role.t()] | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          text: String.t(),
          start_date: LocalizedNaiveDatetime.t(),
          end_date: LocalizedNaiveDatetime.t(),
          related_tenants: Ecto.Schema.many_to_many(Tenant.t()),
          roles: [Role.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "system_messages" do
    field :text, :string
    field :start_date, LocalizedNaiveDatetime
    field :end_date, LocalizedNaiveDatetime
    field :roles, {:array, Role}

    many_to_many :related_tenants, Tenant,
      join_through: "system_message_tenants",
      join_keys: [system_message_uuid: :uuid, tenant_uuid: :uuid],
      on_replace: :delete

    timestamps()
  end

  @spec changeset(system_message :: empty | t, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(system_message, attrs) do
    system_message
    |> cast(attrs, [:text, :start_date, :end_date, :roles])
    |> validate_required([:text, :start_date, :end_date, :roles])
    |> cast_many_to_many(:related_tenants)
  end

  defp cast_many_to_many(%Changeset{params: params} = changeset, field) do
    params
    |> Map.take([field, Atom.to_string(field)])
    |> Map.values()
    |> case do
      [] ->
        changeset

      [_ | _] = fields ->
        related_tenant_ids = List.flatten(fields)

        related_tenants =
          Repo.all(
            from(tenant in Tenant,
              where: tenant.uuid in ^related_tenant_ids
            )
          )

        put_assoc(changeset, field, related_tenants)
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.SystemMessageContext.SystemMessage
    alias Hygeia.UserContext.User

    @spec preload(resource :: SystemMessage.t()) :: SystemMessage.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: SystemMessage.t(),
            action :: :create | :details | :list | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_system_message, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_system_message, action, %Person{}, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_system_message, action, user, _meta)
        when action in [:details, :list],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_system_message, action, user, _meta)
        when action in [:create, :update, :delete],
        do: Enum.any?([:super_user, :admin, :webmaster], &User.has_role?(user, &1, :any))
  end
end
