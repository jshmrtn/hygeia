defmodule Hygeia.TenantContext do
  @moduledoc """
  The TenantContext context.
  """

  use Hygeia, :context

  alias Hygeia.TenantContext.Tenant

  @doc """
  Returns the list of tenants.

  ## Examples

      iex> list_tenants()
      [%Tenant{}, ...]

  """
  @spec list_tenants :: [Tenant.t()]
  def list_tenants, do: Repo.all(Tenant)

  @doc """
  Gets a single tenant.

  Raises `Ecto.NoResultsError` if the Tenant does not exist.

  ## Examples

      iex> get_tenant!(123)
      %Tenant{}

      iex> get_tenant!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_tenant!(id :: String.t()) :: Tenant.t()
  def get_tenant!(id), do: Repo.get!(Tenant, id)

  @doc """
  Creates a tenant.

  ## Examples

      iex> create_tenant(%{field: value})
      {:ok, %Tenant{}}

      iex> create_tenant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_tenant(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t(Tenant.t())}
  def create_tenant(attrs \\ %{}),
    do:
      %Tenant{}
      |> change_tenant(attrs)
      |> versioning_insert()
      |> broadcast("tenants", :create)
      |> versioning_extract()

  @doc """
  Updates a tenant.

  ## Examples

      iex> update_tenant(tenant, %{field: new_value})
      {:ok, %Tenant{}}

      iex> update_tenant(tenant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_tenant(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t(Tenant.t())}
  def update_tenant(%Tenant{} = tenant, attrs),
    do:
      tenant
      |> change_tenant(attrs)
      |> versioning_update()
      |> broadcast("tenants", :update)
      |> versioning_extract()

  @doc """
  Deletes a tenant.

  ## Examples

      iex> delete_tenant(tenant)
      {:ok, %Tenant{}}

      iex> delete_tenant(tenant)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_tenant(tenant :: Tenant.t()) ::
          {:ok, Tenant.t()} | {:error, Ecto.Changeset.t(Tenant.t())}
  def delete_tenant(%Tenant{} = tenant),
    do:
      tenant
      |> change_tenant()
      |> versioning_delete()
      |> broadcast("tenants", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant changes.

  ## Examples

      iex> change_tenant(tenant)
      %Ecto.Changeset{data: %Tenant{}}

  """
  @spec change_tenant(
          tenant :: Tenant.t() | Tenant.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Tenant.t())
  def change_tenant(%Tenant{} = tenant, attrs \\ %{}), do: Tenant.changeset(tenant, attrs)
end
