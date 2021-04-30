defmodule Hygeia.OrganisationContext do
  @moduledoc """
  The OrganisationContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Position

  @doc """
  Returns the list of organisations.

  ## Examples

      iex> list_organisations()
      [%Organisation{}, ...]

  """
  @spec list_organisations :: [Organisation.t()]
  def list_organisations, do: Repo.all(list_organisations_query())

  @spec list_organisations_query :: Ecto.Queryable.t()
  def list_organisations_query,
    do: from(organisation in Organisation, order_by: organisation.name)

  @spec list_organisations_by_ids(ids :: [String.t()]) :: [Organisation.t()]
  def list_organisations_by_ids(ids)
  def list_organisations_by_ids([]), do: []

  def list_organisations_by_ids(ids),
    do:
      Repo.all(from(organisation in list_organisations_query(), where: organisation.uuid in ^ids))

  @spec list_possible_organisation_duplicates(organisation :: Organisation.t()) ::
          Ecto.Queryable.t()
  def list_possible_organisation_duplicates(
        %Organisation{name: name, address: address, uuid: uuid} = _organisation
      ),
      do:
        list_organisations_query()
        |> filter_similar_organisation_names(name)
        |> filter_same_organisation_address(address)
        |> remove_uuid(uuid)
        |> Repo.all()

  defp filter_similar_organisation_names(query, name),
    do: from(organisation in query, where: fragment("? % ?", ^name, organisation.name))

  defp filter_same_organisation_address(query, nil), do: query

  defp filter_same_organisation_address(query, %Address{address: nil}), do: query
  defp filter_same_organisation_address(query, %Address{address: ""}), do: query

  defp filter_same_organisation_address(query, %Address{
         address: address,
         zip: zip,
         place: place,
         country: country
       }),
       do:
         from(organisation in query,
           or_where:
             fragment(
               "? <@ ?",
               ^%{address: address, zip: zip, place: place, country: country},
               organisation.address
             )
         )

  defp remove_uuid(query, nil), do: query

  defp remove_uuid(query, uuid),
    do: from(organisation in query, where: organisation.uuid != ^uuid)

  @spec fulltext_organisation_search_query(query :: String.t(), limit :: pos_integer()) ::
          Ecto.Query.t()
  def fulltext_organisation_search_query(query, limit \\ 10),
    do:
      from(organisation in Organisation,
        where: fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", organisation, ^query),
        order_by: [
          desc:
            fragment(
              "TS_RANK_CD(?.fulltext, WEBSEARCH_TO_TSQUERY('german', ?))",
              organisation,
              ^query
            )
        ],
        limit: ^limit
      )

  @spec fulltext_organisation_search(query :: String.t(), limit :: pos_integer()) :: [
          Organisation.t()
        ]
  def fulltext_organisation_search(query, limit \\ 10),
    do: Repo.all(fulltext_organisation_search_query(query, limit))

  @doc """
  Gets a single organisation.

  Raises `Ecto.NoResultsError` if the Organisation does not exist.

  ## Examples

      iex> get_organisation!(123)
      %Organisation{}

      iex> get_organisation!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_organisation!(id :: Ecto.UUID.t()) :: Organisation.t()
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
      attrs
      |> change_new_organisation()
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

  @spec merge_organisations(delete :: Organisation.t(), into :: Organisation.t()) ::
          {:ok, Organisation.t()}
  def merge_organisations(
        %Organisation{uuid: delete_uuid} = delete,
        %Organisation{uuid: into_uuid} = _into
      ) do
    Repo.transaction(fn ->
      affiliation_updates =
        delete
        |> Ecto.assoc(:affiliations)
        |> Repo.stream()
        |> Enum.reduce(Ecto.Multi.new(), fn %Affiliation{uuid: uuid} = affiliation, acc ->
          Ecto.Multi.update(
            acc,
            uuid,
            Ecto.Changeset.change(affiliation, %{organisation_uuid: into_uuid})
          )
        end)

      position_updates =
        delete
        |> Ecto.assoc(:positions)
        |> Repo.stream()
        |> Enum.reduce(Ecto.Multi.new(), fn %Position{uuid: uuid} = position, acc ->
          Ecto.Multi.update(
            acc,
            uuid,
            Ecto.Changeset.change(position, %{organisation_uuid: into_uuid})
          )
        end)

      division_updates =
        delete
        |> Ecto.assoc(:divisions)
        |> Repo.stream()
        |> Enum.reduce(Ecto.Multi.new(), fn %Division{uuid: uuid} = division, acc ->
          Ecto.Multi.update(
            acc,
            uuid,
            Ecto.Changeset.change(division, %{organisation_uuid: into_uuid})
          )
        end)

      {:ok, _updates} =
        affiliation_updates
        |> Ecto.Multi.append(position_updates)
        |> Ecto.Multi.append(division_updates)
        |> Ecto.Multi.delete({:delete, delete_uuid}, Ecto.Changeset.change(delete))
        |> authenticate_multi()
        |> Repo.transaction()

      get_organisation!(into_uuid)
    end)
  end

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
  def delete_organisation(%Organisation{} = organisation) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:affiliations, Ecto.assoc(organisation, :affiliations),
      set: [comment: organisation.name]
    )
    |> Ecto.Multi.delete(:organisation, change_organisation(organisation))
    |> authenticate_multi()
    |> Repo.transaction()
    |> case do
      {:ok, %{organisation: organisation}} -> {:ok, organisation}
      {:error, _name, error, _acc} -> {:error, error}
    end
    |> broadcast("organisations", :delete)
    |> versioning_extract()
  end

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

  @spec change_new_organisation(attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Organisation.t())
  def change_new_organisation(attrs \\ %{}), do: change_organisation(%Organisation{}, attrs)

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
  @spec get_position!(id :: Ecto.UUID.t()) :: Position.t()
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
  def delete_position(%Position{} = position),
    do:
      position
      |> change_position()
      |> versioning_delete()
      |> broadcast("positions", :delete)
      |> versioning_extract()

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

  @doc """
  Returns the list of affiliations.

  ## Examples

      iex> list_affiliations()
      [%Affiliation{}, ...]

  """
  @spec list_affiliations :: [Affiliation.t()]
  def list_affiliations, do: Repo.all(Affiliation)

  @doc """
  Gets a single affiliation.

  Raises `Ecto.NoResultsError` if the Affiliation does not exist.

  ## Examples

      iex> get_affiliation!(123)
      %Affiliation{}

      iex> get_affiliation!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_affiliation!(id :: Ecto.UUID.t()) :: Affiliation.t()
  def get_affiliation!(id), do: Repo.get!(Affiliation, id)

  @doc """
  Creates a affiliation.

  ## Examples

      iex> create_affiliation(%{field: value})
      {:ok, %Affiliation{}}

      iex> create_affiliation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_affiliation(
          person :: Person.t(),
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, Affiliation.t()} | {:error, Ecto.Changeset.t(Affiliation.t())}
  def create_affiliation(
        %Person{} = person,
        %Organisation{uuid: organisation_uuid} = _organisation,
        attrs \\ %{}
      ),
      do:
        person
        |> Ecto.build_assoc(:affiliations, %{organisation_uuid: organisation_uuid})
        |> change_affiliation(attrs)
        |> versioning_insert()
        |> broadcast(
          "affiliations",
          :create,
          & &1.uuid,
          &["people:#{&1.person_uuid}", "organisations:#{&1.organisation_uuid}"]
        )
        |> versioning_extract()

  @doc """
  Updates a affiliation.

  ## Examples

      iex> update_affiliation(affiliation, %{field: new_value})
      {:ok, %Affiliation{}}

      iex> update_affiliation(affiliation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_affiliation(
          affiliation :: Affiliation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, Affiliation.t()} | {:error, Ecto.Changeset.t(Affiliation.t())}
  def update_affiliation(%Affiliation{} = affiliation, attrs),
    do:
      affiliation
      |> change_affiliation(attrs)
      |> versioning_update()
      |> broadcast(
        "affiliations",
        :update,
        & &1.uuid,
        &["people:#{&1.person_uuid}", "organisations:#{&1.organisation_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Deletes a affiliation.

  ## Examples

      iex> delete_affiliation(affiliation)
      {:ok, %Affiliation{}}

      iex> delete_affiliation(affiliation)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_affiliation(affiliation :: Affiliation.t()) ::
          {:ok, Affiliation.t()} | {:error, Ecto.Changeset.t(Affiliation.t())}
  def delete_affiliation(%Affiliation{} = affiliation),
    do:
      affiliation
      |> change_affiliation()
      |> versioning_delete()
      |> broadcast(
        "affiliations",
        :delete,
        & &1.uuid,
        &["people:#{&1.person_uuid}", "organisations:#{&1.organisation_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking affiliation changes.

  ## Examples

      iex> change_affiliation(affiliation)
      %Ecto.Changeset{data: %Affiliation{}}

  """
  @spec change_affiliation(
          affiliation :: resource | Ecto.Changeset.t(resource),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(resource)
        when resource: Affiliation.t() | Affiliation.empty()
  def change_affiliation(affiliation, attrs \\ %{}), do: Affiliation.changeset(affiliation, attrs)

  @doc """
  Returns the list of divisions.

  ## Examples

      iex> list_divisions()
      [%Division{}, ...]

  """
  @spec list_divisions :: [Division.t()]
  def list_divisions, do: Repo.all(Division)

  @spec list_divisions_query(organisation_uuid :: Ecto.UUID.t()) :: Ecto.Query.t()
  def list_divisions_query(organisation_uuid) when is_binary(organisation_uuid),
    do: from(division in Division, where: division.organisation_uuid == ^organisation_uuid)

  @spec fulltext_division_search_query(
          organisation_uuid :: Ecto.UUID.t(),
          query :: String.t(),
          limit :: pos_integer()
        ) ::
          Ecto.Query.t()
  def fulltext_division_search_query(organisation_uuid, query, limit \\ 10),
    do:
      from(division in list_divisions_query(organisation_uuid),
        where:
          fragment("? % ?::text", ^query, division.uuid) or
            fragment("? % ?", division.title, ^query) or
            fragment("? % ?", division.description, ^query),
        order_by: [division.title],
        limit: ^limit
      )

  @doc """
  Gets a single division.

  Raises `Ecto.NoResultsError` if the Division does not exist.

  ## Examples

      iex> get_division!(123)
      %Division{}

      iex> get_division!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_division!(id :: Ecto.UUID.t()) :: Division.t()
  def get_division!(id), do: Repo.get!(Division, id)

  @doc """
  Creates a division.

  ## Examples

      iex> create_division(%{field: value})
      {:ok, %Division{}}

      iex> create_division(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_division(organisation :: Organisation.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Division.t()} | {:error, Ecto.Changeset.t(Division.t())}
  def create_division(organisation, attrs \\ %{}),
    do:
      organisation
      |> change_new_division(attrs)
      |> versioning_insert()
      |> broadcast("divisions", :create)
      |> versioning_extract()

  @doc """
  Updates a division.

  ## Examples

      iex> update_division(division, %{field: new_value})
      {:ok, %Division{}}

      iex> update_division(division, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_division(division :: Division.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Division.t()} | {:error, Ecto.Changeset.t(Division.t())}
  def update_division(%Division{} = division, attrs),
    do:
      division
      |> change_division(attrs)
      |> versioning_update()
      |> broadcast("divisions", :update)
      |> versioning_extract()

  @doc """
  Deletes a division.

  ## Examples

      iex> delete_division(division)
      {:ok, %Division{}}

      iex> delete_division(division)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_division(division :: Division.t()) ::
          {:ok, Division.t()} | {:error, Ecto.Changeset.t(Division.t())}
  def delete_division(%Division{} = division),
    do:
      division
      |> change_division()
      |> versioning_delete()
      |> broadcast("divisions", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking division changes.

  ## Examples

      iex> change_division(division)
      %Ecto.Changeset{data: %Division{}}

  """
  @spec change_division(division :: Division.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Division.t())
  def change_division(%Division{} = division, attrs \\ %{}),
    do: Division.changeset(division, attrs)

  @spec change_new_division(
          organisation :: Organisation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Division.t())
  def change_new_division(%Organisation{} = organisation, attrs \\ %{}),
    do:
      organisation
      |> Ecto.build_assoc(:divisions)
      |> change_division(attrs)

  @spec merge_divisions(delete :: Division.t(), into :: Division.t()) ::
          {:ok, Division.t()}
  def merge_divisions(
        %Division{uuid: delete_uuid} = delete,
        %Division{uuid: into_uuid} = _into
      ) do
    Repo.transaction(fn ->
      affiliation_updates =
        delete
        |> Ecto.assoc(:affiliations)
        |> Repo.stream()
        |> Enum.reduce(Ecto.Multi.new(), fn %Affiliation{uuid: uuid} = affiliation, acc ->
          Ecto.Multi.update(
            acc,
            uuid,
            Ecto.Changeset.change(affiliation, %{division_uuid: into_uuid})
          )
        end)

      {:ok, _updates} =
        affiliation_updates
        |> Ecto.Multi.delete({:delete, delete_uuid}, Ecto.Changeset.change(delete))
        |> authenticate_multi()
        |> Repo.transaction()

      get_division!(into_uuid)
    end)
  end

  @spec has_affiliations?(organisation :: Organisation.t()) :: boolean
  def has_affiliations?(%Organisation{} = organisation) do
    case Repo.preload(organisation, :affiliations) do
      %Organisation{affiliations: []} -> false
      %Organisation{} -> true
    end
  end

  @spec has_affiliations?(division :: Division.t()) :: boolean
  def has_affiliations?(%Division{} = division) do
    case Repo.preload(division, :affiliations) do
      %Division{affiliations: []} -> false
      %Division{} -> true
    end
  end
end
