defmodule Hygeia.UserContext do
  @moduledoc """
  The UserContext context.
  """

  use Hygeia, :context

  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.Grant.Role
  alias Hygeia.UserContext.User

  @doc """
  Returns the list of user.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  @spec list_users :: [User.t()]
  def list_users, do: Repo.all(from(user in User, order_by: user.display_name))

  @spec list_users_with_role(role :: Role.t(), tenant :: :any) :: [User.t()]
  def list_users_with_role(role, :any),
    do:
      Repo.all(
        from(user in User,
          join: grant in assoc(user, :grants),
          preload: [grants: grant],
          where: grant.role == ^role,
          order_by: user.display_name
        )
      )

  @spec list_users_with_role(role :: Role.t(), tenants :: [Tenant.t()]) :: [User.t()]
  def list_users_with_role(role, tenants) when is_list(tenants),
    do:
      Repo.all(
        from(user in User,
          join: grant in assoc(user, :grants),
          preload: [grants: grant],
          where: grant.role == ^role and grant.tenant_uuid in ^Enum.map(tenants, & &1.uuid),
          order_by: user.display_name
        )
      )

  @spec list_users_with_role(role :: Role.t(), tenant :: Tenant.t()) :: [User.t()]
  def list_users_with_role(role, %Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(user in User,
          join: grant in assoc(user, :grants),
          preload: [grants: grant],
          where: grant.role == ^role and grant.tenant_uuid == ^tenant_uuid,
          order_by: user.display_name
        )
      )

  @spec fulltext_user_search(query :: String.t(), limit :: pos_integer()) :: [User.t()]
  def fulltext_user_search(query, limit \\ 10),
    do:
      Repo.all(
        from(user in User,
          where:
            fragment("? % ?::text", ^query, user.uuid) or
              fragment("? % ?", ^query, user.display_name) or
              fragment("? % ?", ^query, user.email),
          limit: ^limit
        )
      )

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

  @spec get_user_by_sub!(sub :: String.t()) :: User.t()
  def get_user_by_sub!(sub), do: Repo.get_by!(User, iam_sub: sub)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t(User.t())}
  def create_user(attrs \\ %{}),
    do:
      %User{}
      |> change_user(attrs)
      |> versioning_insert()
      |> broadcast("users", :create)
      |> versioning_extract()

  @spec upsert_user(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t(User.t())}
  def upsert_user(%{iam_sub: sub} = attrs) do
    attrs
    |> create_user()
    |> case do
      {:ok, user} ->
        {:ok, Repo.preload(user, :grants)}

      {:error,
       %Ecto.Changeset{
         errors: [
           iam_sub: {_message, [constraint: :unique, constraint_name: "users_iam_sub_index"]}
         ]
       }} ->
        user =
          sub
          |> get_user_by_sub!()
          |> Repo.preload(:grants)

        if user_identical_after_update?(user, attrs) do
          {:ok, user}
        else
          update_user(user, attrs)
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @spec user_identical_after_update?(
          user_before :: User.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: boolean
  def user_identical_after_update?(user_before, attrs),
    do:
      cmp_user_fields(user_before) ==
        user_before
        |> change_user(attrs)
        |> Ecto.Changeset.apply_changes()
        |> cmp_user_fields()

  @abnormal_fields [:__meta__, :grants, :inserted_at, :updated_at, :tenants, :uuid]
  defp cmp_user_fields(%User{grants: grants} = user) do
    user
    |> Map.from_struct()
    |> Map.drop(@abnormal_fields)
    |> Map.put(:grants, grants |> Enum.map(&{&1.role, &1.tenant_uuid}) |> Enum.sort())
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(user :: User.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t(User.t())}
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
  @spec delete_user(user :: User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t(User.t())}
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
