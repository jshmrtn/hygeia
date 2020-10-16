defmodule Hygeia.OrganisationContext do
  @moduledoc """
  The OrganisationContext context.
  """

  use Hygeia, :context

  alias Hygeia.OrganisationContext.Organisation

  @doc """
  Returns the list of organisations.

  ## Examples

      iex> list_organisations()
      [%Organisation{}, ...]

  """
  @spec list_organisations :: [Organisation.t()]
  def list_organisations, do: Repo.all(Organisation)

  @doc """
  Gets a single organisation.

  Raises `Ecto.NoResultsError` if the Organisation does not exist.

  ## Examples

      iex> get_organisation!(123)
      %Organisation{}

      iex> get_organisation!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_organisation!(id :: String.t()) :: Organisation.t()
  def get_organisation!(id), do: Repo.get!(Organisation, id)

  @doc """
  Creates a organisation.

  ## Examples

      iex> create_organisation(%{field: value})
      {:ok, %Organisation{}}

      iex> create_organisation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_organisation(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t()}
  def create_organisation(attrs \\ %{}),
    do:
      %Organisation{}
      |> change_organisation(attrs)
      |> versioning_insert()
      |> broadcast("organisations", :create)
      |> versioning_extract()

  @doc """
  Updates a organisation.

  ## Examples

      iex> update_organisation(organisation, %{field: new_value})
      {:ok, %Organisation{}}

      iex> update_organisation(organisation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_organisation(
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t()}
  def update_organisation(%Organisation{} = organisation, attrs),
    do:
      organisation
      |> change_organisation(attrs)
      |> versioning_update()
      |> broadcast("organisations", :update)
      |> versioning_extract()

  @doc """
  Deletes a organisation.

  ## Examples

      iex> delete_organisation(organisation)
      {:ok, %Organisation{}}

      iex> delete_organisation(organisation)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_organisation(organisation :: Organisation.t()) ::
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t()}
  def delete_organisation(%Organisation{} = organisation),
    do:
      organisation
      |> change_organisation()
      |> versioning_delete()
      |> broadcast("organisations", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organisation changes.

  ## Examples

      iex> change_organisation(organisation)
      %Ecto.Changeset{data: %Organisation{}}

  """
  @spec change_organisation(
          organisation :: Organisation.t() | Organisation.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end
end
