defmodule Hygeia.PoliticalTerritoryContext do
  @moduledoc """
  The PoliticalTerritoryContext context.
  """

  use Hygeia, :context

  alias Hygeia.PoliticalTerritoryContext.PoliticalTerritory

  @doc """
  Returns the list of political_territories.

  ## Examples

      iex> list_political_territories()
      [%PoliticalTerritory{}, ...]

  """
  @spec list_political_territories :: [PoliticalTerritory.t()]
  def list_political_territories, do: Repo.all(PoliticalTerritory)

  @doc """
  Gets a single political territory.

  Raises `Ecto.NoResultsError` if the PoliticalTerritory does not exist.

  ## Examples

      iex> get_political_territory!(123)
      %PoliticalTerritory{}

      iex> get_political_territory!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_political_territory!(id :: Ecto.UUID.t()) :: PoliticalTerritory.t()
  def get_political_territory!(id), do: Repo.get!(PoliticalTerritory, id)

  @spec get_political_territory_by_ism_code(ism_code :: integer()) :: PoliticalTerritory.t() | nil
  def get_political_territory_by_ism_code(ism_code)
      when is_integer(ism_code),
      do: Repo.get_by(PoliticalTerritory, ism_code: ism_code)

  @doc """
  Creates a political territory.

  ## Examples

      iex> create_political_territory(%{field: value})
      {:ok, %PoliticalTerritory{}}

      iex> create_political_territory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_political_territory(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, PoliticalTerritory.t()} | {:error, Ecto.Changeset.t(PoliticalTerritory.t())}
  def create_political_territory(attrs \\ %{}),
    do:
      %PoliticalTerritory{}
      |> change_political_territory(attrs)
      |> versioning_insert()
      |> broadcast("political_territories", :create)
      |> versioning_extract()

  @doc """
  Updates a political territory.

  ## Examples

      iex> update_political_territory(political_territory, %{field: new_value})
      {:ok, %PoliticalTerritory{}}

      iex> update_political_territory(political_territory, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_political_territory(
          political_territory :: PoliticalTerritory.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, PoliticalTerritory.t()} | {:error, Ecto.Changeset.t(PoliticalTerritory.t())}
  def update_political_territory(%PoliticalTerritory{} = political_territory, attrs),
    do:
      political_territory
      |> change_political_territory(attrs)
      |> versioning_update()
      |> broadcast("political_territories", :update)
      |> versioning_extract()

  @doc """
  Deletes a political territory.

  ## Examples

      iex> delete_political_territory(political_territory)
      {:ok, %PoliticalTerritory{}}

      iex> delete_political_territory(political_territory)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_political_territory(political_territory :: PoliticalTerritory.t()) ::
          {:ok, PoliticalTerritory.t()} | {:error, Ecto.Changeset.t(PoliticalTerritory.t())}
  def delete_political_territory(%PoliticalTerritory{} = political_territory),
    do:
      political_territory
      |> change_political_territory()
      |> versioning_delete()
      |> broadcast("political_territories", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking political territory changes.

  ## Examples

      iex> change_political_territory(political_territory)
      %Ecto.Changeset{data: %PoliticalTerritory{}}

  """
  @spec change_political_territory(
          political_territory :: PoliticalTerritory.t() | PoliticalTerritory.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(PoliticalTerritory.t())
  def change_political_territory(%PoliticalTerritory{} = political_territory, attrs \\ %{}),
    do: PoliticalTerritory.changeset(political_territory, attrs)
end
