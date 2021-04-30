defmodule Hygeia.ImportContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  import Hygeia.ImportContext.Utility

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row
  alias Hygeia.TenantContext.Tenant

  @mime_type_csv MIME.type("csv")
  @mime_type_xlsx MIME.type("xlsx")

  @doc """
  Returns the list of imports.

  ## Examples

      iex> list_imports()
      [%Import{}, ...]

  """
  @spec list_imports :: [Import.t()]
  def list_imports, do: Repo.all(Import)

  @doc """
  Gets a single import.

  Raises `Ecto.NoResultsError` if the Import does not exist.

  ## Examples

      iex> get_import!(123)
      %Import{}

      iex> get_import!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_import!(id :: Ecto.UUID.t()) :: Import.t()
  def get_import!(id), do: Repo.get!(Import, id)

  @doc """
  Creates a import.

  ## Examples

      iex> create_import(tenant, %{field: value})
      {:ok, %Import{}}

      iex> create_import(tenant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_import(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Import.t()} | {:error, Ecto.Changeset.t(Import.t())}
  def create_import(%Tenant{} = tenant, attrs \\ %{}),
    do:
      tenant
      |> Ecto.build_assoc(:imports)
      |> change_import(attrs)
      |> versioning_insert()
      |> broadcast("imports", :create)
      |> versioning_extract()

  @spec create_import(
          tenant :: Tenant.t(),
          mime :: String.t(),
          file :: Path.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Import.t()}
          | {:error, Ecto.Changeset.t(Import.t()) | {:invalid_import, {:invalid_value, term}}}
  def create_import(%Tenant{} = tenant, mime, file, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :import,
      tenant
      |> Ecto.build_assoc(:imports)
      |> change_import(attrs)
    )
    |> Ecto.Multi.run(:rows, fn repo, %{import: %Import{uuid: import_uuid} = import} ->
      {_count, nil} =
        repo.insert_all(
          Row,
          import
          |> extract_rows(mime, file)
          |> Enum.to_list()
          |> Stream.map(fn {columns, ids} ->
            %{
              data: columns,
              identifiers: ids,
              import_uuid: import_uuid,
              inserted_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now()
            }
          end)
          |> Enum.to_list(),
          returning: false,
          on_conflict: {:replace, [:import_uuid]},
          conflict_target: :data
        )

      {:ok, nil}
    end)
    |> authenticate_multi()
    |> Repo.transaction()
    |> case do
      {:ok, %{import: import}} ->
        {:ok, import}
        |> broadcast("imports", :create)
        |> versioning_extract()

      {:error, _name, reason, _others} ->
        {:error, reason}
    end
  rescue
    e in Hygeia.ImportContext.Utility.InvalidValueError -> {:error, {:invalid_value, e.value}}
  end

  @spec extract_rows(import :: Import.t(), mime :: String.t(), file :: Path.t()) :: Enumerable.t()
  defp extract_rows(%Import{type: type}, @mime_type_xlsx, file) do
    file
    |> Xlsxir.stream_list(0)
    |> Stream.transform(false, &add_headers/2)
    |> Stream.map(&normalize_values!/1)
    |> Stream.reject(fn row ->
      Enum.all?(row, &match?({_key, nil}, &1))
    end)
    |> Stream.map(&{&1, extract_row_identifier(type, &1)})
  end

  defp extract_rows(%Import{type: type}, @mime_type_csv, file) do
    file
    |> File.stream!()
    |> Stream.reject(&match?("", &1))
    |> CSV.decode!(headers: true)
    |> Stream.map(&{&1, extract_row_identifier(type, &1)})
  end

  @doc """
  Updates a import.

  ## Examples

      iex> update_import(import, %{field: new_value})
      {:ok, %Import{}}

      iex> update_import(import, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_import(import :: Import.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Import.t()} | {:error, Ecto.Changeset.t(Import.t())}
  def update_import(%Import{} = import, attrs),
    do:
      import
      |> change_import(attrs)
      |> versioning_update()
      |> broadcast("imports", :update)
      |> versioning_extract()

  @doc """
  Deletes a import.

  ## Examples

      iex> delete_import(import)
      {:ok, %Import{}}

      iex> delete_import(import)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_import(import :: Import.t()) ::
          {:ok, Import.t()} | {:error, Ecto.Changeset.t(Import.t())}
  def delete_import(%Import{} = import),
    do:
      import
      |> change_import()
      |> versioning_delete()
      |> broadcast("imports", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking import changes.

  ## Examples

      iex> change_import(import)
      %Ecto.Changeset{data: %Import{}}

  """
  @spec change_import(
          import :: Import.t() | Import.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Import.t())
  def change_import(%Import{} = import, attrs \\ %{}), do: Import.changeset(import, attrs)

  @doc """
  Returns the list of rows.

  ## Examples

      iex> list_rows()
      [%Row{}, ...]

  """
  @spec list_rows :: [Row.t()]
  def list_rows, do: Repo.all(Row)

  @spec list_rows(import :: Import.t()) :: [Row.t()]
  def list_rows(%Import{} = import), do: import |> Ecto.assoc(:rows) |> Repo.all()

  @doc """
  Gets a single row.

  Raises `Ecto.NoResultsError` if the Row does not exist.

  ## Examples

      iex> get_row!(123)
      %Row{}

      iex> get_row!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_row!(id :: Ecto.UUID.t()) :: Row.t()
  def get_row!(id), do: Repo.get!(Row, id)

  @spec get_row_predecessor(row :: Row.t()) :: Row.t() | nil
  def get_row_predecessor(%Row{uuid: search_uuid} = _row),
    do:
      Repo.one(
        from(search in Row,
          join: search_import in assoc(search, :import),
          join: predecessor_import in Import,
          on:
            predecessor_import.type == search_import.type and
              search_import.change_date > predecessor_import.change_date and
              search_import.tenant_uuid == predecessor_import.tenant_uuid,
          join: predecessor in assoc(predecessor_import, :resolved_rows),
          where: search.uuid == ^search_uuid and predecessor.identifiers == search.identifiers,
          order_by: [desc: predecessor_import.change_date],
          limit: 1,
          select: predecessor
        )
      )

  @doc """
  Creates a row.

  ## Examples

      iex> create_row(%{field: value})
      {:ok, %ImportRow{}}

      iex> create_row(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_row(import :: Import.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Row.t()} | {:error, Ecto.Changeset.t(Row.t())}
  def create_row(%Import{} = import, attrs \\ %{}),
    do:
      import
      |> Ecto.build_assoc(:rows)
      |> change_row(attrs)
      |> versioning_insert()
      |> broadcast("rows", :create)
      |> versioning_extract()

  @doc """
  Updates a row.

  ## Examples

      iex> update_row(row, %{field: new_value})
      {:ok, %ImportRow{}}

      iex> update_row(row, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_row(row :: Row.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Row.t()} | {:error, Ecto.Changeset.t(Row.t())}
  def update_row(%Row{} = row, attrs),
    do:
      row
      |> change_row(attrs)
      |> versioning_update()
      |> broadcast("rows", :update)
      |> versioning_extract()

  @doc """
  Deletes a row.

  ## Examples

      iex> delete_row(row)
      {:ok, %Row{}}

      iex> delete_row(row)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_row(row :: Row.t()) :: {:ok, Row.t()} | {:error, Ecto.Changeset.t(Row.t())}
  def delete_row(%Row{} = row),
    do:
      row
      |> change_row()
      |> versioning_delete()
      |> broadcast("rows", :update)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking row changes.

  ## Examples

      iex> change_row(row)
      %Ecto.Changeset{data: %Row{}}

  """
  @spec change_row(row :: Row.t() | Row.empty(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Row.t())
  def change_row(%Row{} = row, attrs \\ %{}), do: Row.changeset(row, attrs)
end
