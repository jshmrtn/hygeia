defmodule Hygeia.UserContext.User do
  @moduledoc """
  Model for User
  """

  use Hygeia, :model

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          email: String.t() | nil,
          display_name: String.t() | nil,
          iam_sub: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          email: String.t(),
          display_name: String.t(),
          iam_sub: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :iam_sub, :string

    timestamps()
  end

  @doc false
  @spec changeset(user :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :display_name, :iam_sub])
    |> validate_required([:email, :display_name, :iam_sub])
    |> unique_constraint(:iam_sub)
  end
end
