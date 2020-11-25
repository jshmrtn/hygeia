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
  def list_tenants, do: Repo.all(from(tenant in Tenant, order_by: tenant.name))

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

  @spec tenant_has_outgoing_mail_configuration?(tenant :: Tenant.t()) :: boolean
  def tenant_has_outgoing_mail_configuration?(%Tenant{outgoing_mail_configuration: nil}),
    do: false

  def tenant_has_outgoing_mail_configuration?(%Tenant{
        outgoing_mail_configuration: _outgoing_mail_configuration
      }),
      do: true

  @spec tenant_has_outgoing_sms_configuration?(tenant :: Tenant.t()) :: boolean
  def tenant_has_outgoing_sms_configuration?(%Tenant{outgoing_sms_configuration: nil}),
    do: false

  def tenant_has_outgoing_sms_configuration?(%Tenant{
        outgoing_sms_configuration: _outgoing_mail_configuration
      }),
      do: true

  @doc """
  Replaces base url for pdf link if tenant has override url.

  """
  @spec replace_base_url(tenant :: Tenant.t(), pdf_url :: String.t(), base_url :: String.t()) ::
          String.t()
  def replace_base_url(%Tenant{override_url: nil}, pdf_url, _base_url), do: pdf_url
  def replace_base_url(%Tenant{override_url: ""}, pdf_url, _base_url), do: pdf_url

  def replace_base_url(%Tenant{override_url: override_url}, pdf_url, base_url),
    do: String.replace_prefix(pdf_url, base_url, override_url)
end
