defmodule Hygeia.TenantContext do
  @moduledoc """
  The TenantContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext
  alias Hygeia.TenantContext.SedexExport
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
  @spec get_tenant!(id :: Ecto.UUID.t()) :: Tenant.t()
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
      attrs
      |> change_new_tenant()
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

  @spec change_new_tenant(attrs :: Hygeia.ecto_changeset_params()) :: Ecto.Changeset.t(Tenant.t())
  def change_new_tenant(attrs \\ %{}), do: change_tenant(%Tenant{}, attrs)

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

  @doc """
  Returns the list of sedex_exports.

  ## Examples

      iex> list_sedex_exports()
      [%SedexExport{}, ...]

  """
  @spec list_sedex_exports :: [SedexExport.t()]
  def list_sedex_exports, do: Repo.all(SedexExport)

  @spec list_sedex_exports(tenant :: Tenant.t()) :: [SedexExport.t()]
  def list_sedex_exports(tenant), do: tenant |> list_sedex_exports_query() |> Repo.all()

  @spec list_sedex_exports_query(tenant :: Tenant.t()) :: Ecto.Query.t()
  def list_sedex_exports_query(tenant),
    do:
      from(sedex_export in Ecto.assoc(tenant, :sedex_exports),
        order_by: [desc: sedex_export.scheduling_date]
      )

  @spec last_sedex_export(tenant :: Tenant.t()) :: SedexExport.t() | nil
  def last_sedex_export(tenant),
    do:
      Repo.one(
        from(sedex_export in Ecto.assoc(tenant, :sedex_exports),
          order_by: [desc: sedex_export.scheduling_date],
          limit: 1
        )
      )

  @doc """
  Gets a single sedex_export.

  Raises `Ecto.NoResultsError` if the Sedex export does not exist.

  ## Examples

      iex> get_sedex_export!(123)
      %SedexExport{}

      iex> get_sedex_export!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_sedex_export!(id :: Ecto.UUID.t()) :: SedexExport.t()
  def get_sedex_export!(id), do: Repo.get!(SedexExport, id)

  @doc """
  Creates a sedex_export.

  ## Examples

      iex> create_sedex_export(%{field: value})
      {:ok, %SedexExport{}}

      iex> create_sedex_export(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_sedex_export(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, SedexExport.t()} | {:error, Ecto.Changeset.t(SedexExport.t())}
  def create_sedex_export(%Tenant{} = tenant, attrs \\ %{}),
    do:
      tenant
      |> Ecto.build_assoc(:sedex_exports)
      |> change_sedex_export(attrs)
      |> versioning_insert()
      |> broadcast("sedex_exports", :create)
      |> versioning_extract()

  @spec run_sedex_export(tenant :: Tenant.t(), scheduling_date :: NaiveDateTime.t()) ::
          {:ok, SedexExport.t()} | {:error, Ecto.Changeset.t(SedexExport.t())}
  def run_sedex_export(tenant, scheduling_date) do
    Repo.transaction(
      fn ->
        export =
          tenant
          |> create_sedex_export(%{
            status: :sent,
            scheduling_date: scheduling_date
          })
          |> case do
            {:ok, export} -> export
            {:error, reason} -> Repo.rollback(reason)
          end

        case_export = CaseContext.case_export(tenant, :bag_med_16122020_case)
        contact_export = CaseContext.case_export(tenant, :bag_med_16122020_contact)

        :ok =
          Sedex.send(
            %{"case.csv" => case_export, "contact.csv" => contact_export},
            case tenant.short_name do
              nil -> raise "Tenant Short Name required"
              name when is_binary(name) -> name
            end,
            %{
              message_id: export.uuid,
              message_type: "1150",
              message_class: 0,
              sender_id:
                :hygeia |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(:sedex_sender_id),
              recipient_id: [tenant.sedex_export_configuration.recipient_id],
              event_date: DateTime.from_naive!(export.scheduling_date, "Etc/UTC")
            },
            tenant.sedex_export_configuration.recipient_public_key
          )

        export
      end,
      timeout: :timer.minutes(5)
    )
  end

  @doc """
  Updates a sedex_export.

  ## Examples

      iex> update_sedex_export(sedex_export, %{field: new_value})
      {:ok, %SedexExport{}}

      iex> update_sedex_export(sedex_export, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_sedex_export(
          sedex_export :: SedexExport.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, SedexExport.t()} | {:error, Ecto.Changeset.t(SedexExport.t())}
  def update_sedex_export(%SedexExport{} = sedex_export, attrs),
    do:
      sedex_export
      |> change_sedex_export(attrs)
      |> versioning_update()
      |> broadcast("sedex_exports", :update)
      |> versioning_extract()

  @doc """
  Deletes a sedex_export.

  ## Examples

      iex> delete_sedex_export(sedex_export)
      {:ok, %SedexExport{}}

      iex> delete_sedex_export(sedex_export)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_sedex_export(sedex_export :: SedexExport.t()) ::
          {:ok, SedexExport.t()} | {:error, Ecto.Changeset.t(SedexExport.t())}
  def delete_sedex_export(%SedexExport{} = sedex_export),
    do:
      sedex_export
      |> change_sedex_export
      |> versioning_delete()
      |> broadcast("sedex_exports", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sedex_export changes.

  ## Examples

      iex> change_sedex_export(sedex_export)
      %Ecto.Changeset{data: %SedexExport{}}

  """
  @spec change_sedex_export(
          sedex_export :: SedexExport.t() | SedexExport.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(SedexExport.t() | SedexExport.empty())
  def change_sedex_export(%SedexExport{} = sedex_export, attrs \\ %{}),
    do: SedexExport.changeset(sedex_export, attrs)
end
