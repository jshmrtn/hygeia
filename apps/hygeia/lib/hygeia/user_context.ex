defmodule Hygeia.UserContext do
  @moduledoc """
  The UserContext context.
  """

  use Hygeia, :context

  alias Hygeia.UserContext.User

  @doc """
  Returns the list of user.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  @spec list_users :: [User.t()]
  def list_users, do: Repo.all(User)

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(id :: String.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs \\ %{}),
    do:
      %User{}
      |> change_user(attrs)
      |> versioning_insert()
      |> broadcast("users", :create)
      |> versioning_extract()

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(user :: User.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs),
    do:
      user
      |> change_user(attrs)
      |> versioning_update()
      |> broadcast("users", :update)
      |> versioning_extract()

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(user :: User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user),
    do:
      user
      |> change_user()
      |> versioning_delete()
      |> broadcast("users", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user(
          user :: User.t() | User.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
