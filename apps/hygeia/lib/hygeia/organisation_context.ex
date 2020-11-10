defmodule Hygeia.OrganisationContext do
  @moduledoc """
  The OrganisationContext context.
  """

  use Hygeia, :context

  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Position

  @doc """
  Returns the list of organisations.

  ## Examples

      iex> list_organisations()
      [%Organisation{}, ...]

  """
  @spec list_organisations :: [Organisation.t()]
  def list_organisations, do: Repo.all(Organisation)

  @spec fulltext_organisation_search(query :: String.t(), limit :: pos_integer()) :: [
          Organisation.t()
        ]
  def fulltext_organisation_search(query, limit \\ 10),
    do:
      Repo.all(
        from(organisation in Organisation,
          where:
            fragment("? % ?::text", ^query, organisation.uuid) or
              fragment("? % ?", ^query, organisation.name) or
              fragment("? % (?->'address')::text", ^query, organisation.address) or
              fragment("? % (?->'zip')::text", ^query, organisation.address) or
              fragment("? % (?->'place')::text", ^query, organisation.address) or
              fragment("? % (?->'subdivision')::text", ^query, organisation.address) or
              fragment("? % (?->'country')::text", ^query, organisation.address),
          limit: ^limit
        )
      )

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
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t(Organisation.t())}
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
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t(Organisation.t())}
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
          {:ok, Organisation.t()} | {:error, Ecto.Changeset.t(Organisation.t())}
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
          Ecto.Changeset.t(Organisation.t())
  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  @doc """
  Returns the list of positions.

  ## Examples

      iex> list_positions()
      [%Position{}, ...]

  """
  @spec list_positions :: [Position.t()]
  def list_positions, do: Repo.all(Position)

  @doc """
  Gets a single position.

  Raises `Ecto.NoResultsError` if the Position does not exist.

  ## Examples

      iex> get_position!(123)
      %Position{}

      iex> get_position!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_position!(id :: String.t()) :: Position.t()
  def get_position!(id), do: Repo.get!(Position, id)

  @doc """
  Creates a position.

  ## Examples

      iex> create_position(%{field: value})
      {:ok, %Position{}}

      iex> create_position(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_position(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Position.t()} | {:error, Ecto.Changeset.t(Position.t())}
  def create_position(attrs \\ %{}) do
    %Position{}
    |> change_position(attrs)
    |> versioning_insert()
    |> broadcast("positions", :create)
    |> versioning_extract()
  end

  @doc """
  Updates a position.

  ## Examples

      iex> update_position(position, %{field: new_value})
      {:ok, %Position{}}

      iex> update_position(position, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_position(
          position :: Position.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Position.t()} | {:error, Ecto.Changeset.t(Position.t())}
  def update_position(%Position{} = position, attrs) do
    position
    |> change_position(attrs)
    |> versioning_update()
    |> broadcast("positions", :update)
    |> versioning_extract()
  end

  @doc """
  Deletes a position.

  ## Examples

      iex> delete_position(position)
      {:ok, %Position{}}

      iex> delete_position(position)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_position(position :: Position.t()) ::
          {:ok, Position.t()} | {:error, Ecto.Changeset.t(Position.t())}
  def delete_position(%Position{} = position) do
    position
    |> change_position()
    |> versioning_delete()
    |> broadcast("positions", :delete)
    |> versioning_extract()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking position changes.

  ## Examples

      iex> change_position(position)
      %Ecto.Changeset{data: %Position{}}

  """
  @spec change_position(
          position :: Position.t() | Position.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Position.t())
  def change_position(%Position{} = position, attrs \\ %{}) do
    Position.changeset(position, attrs)
  end
end
