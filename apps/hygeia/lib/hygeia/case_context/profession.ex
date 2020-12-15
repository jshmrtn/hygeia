defmodule Hygeia.CaseContext.Profession do
  @moduledoc """
  Model for Person / Profession Schema
  """

  use Hygeia, :model

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "professions" do
    field :name, :string

    timestamps()
  end

  @doc false
  @spec changeset(profession :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(profession, attrs) do
    profession
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Profession
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: Profession.t(),
            action :: :create | :list | :details | :update | :delete,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_profession, action, _user, _meta)
        when action in [:list, :details],
        do: true

    def authorized?(_profession, action, :anonymous, _meta)
        when action in [:create, :update, :delete],
        do: false

    def authorized?(_profession, action, user, _meta)
        when action in [:create, :update, :delete],
        do: User.has_role?(user, :webmaster, :any)
  end
end
