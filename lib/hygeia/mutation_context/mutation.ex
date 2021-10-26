defmodule Hygeia.MutationContext.Mutation do
  @moduledoc """
  Model for Mutations
  """

  use Hygeia, :model

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          ism_code: integer() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          name: String.t(),
          ism_code: integer()
        }

  schema "mutations" do
    field :name, :string
    field :ism_code, :integer

    timestamps()
  end

  @doc false
  @spec changeset(mutation :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(mutation, attrs) do
    mutation
    |> cast(attrs, [:name, :ism_code])
    |> validate_required([:name, :ism_code])
    |> unique_constraint(:ism_code)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.MutationContext.Mutation
    alias Hygeia.UserContext.User

    @spec preload(resource :: Mutation.t()) :: Mutation.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Mutation.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_mutation, action, :anonymous, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_mutation, action, %Person{}, _meta)
        when action in [:list, :create, :details, :update, :delete],
        do: false

    def authorized?(_mutation, action, user, _meta)
        when action in [:details, :list, :versioning, :deleted_versioning],
        do:
          Enum.any?(
            [:viewer, :tracer, :super_user, :supervisor, :admin],
            &User.has_role?(user, &1, :any)
          )

    def authorized?(_mutation, action, user, _meta)
        when action in [:create, :update, :delete],
        do: Enum.any?([:admin], &User.has_role?(user, &1, :any))
  end
end
