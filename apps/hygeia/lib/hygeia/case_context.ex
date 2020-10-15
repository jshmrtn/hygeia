defmodule Hygeia.CaseContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Profession
  alias Hygeia.TenantContext.Tenant

  @doc """
  Returns the list of professions.

  ## Examples

      iex> list_professions()
      [%Profession{}, ...]

  """
  @spec list_professions :: [Profession.t()]
  def list_professions, do: Repo.all(Profession)

  @doc """
  Gets a single profession.

  Raises `Ecto.NoResultsError` if the Profession does not exist.

  ## Examples

      iex> get_profession!(123)
      %Profession{}

      iex> get_profession!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_profession!(id :: String.t()) :: Profession.t()
  def get_profession!(id), do: Repo.get!(Profession, id)

  @doc """
  Creates a profession.

  ## Examples

      iex> create_profession(%{field: value})
      {:ok, %Profession{}}

      iex> create_profession(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_profession(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def create_profession(attrs \\ %{}),
    do:
      %Profession{}
      |> change_profession(attrs)
      |> versioning_insert()
      |> broadcast("professions", :create)
      |> versioning_extract()

  @doc """
  Updates a profession.

  ## Examples

      iex> update_profession(profession, %{field: new_value})
      {:ok, %Profession{}}

      iex> update_profession(profession, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_profession(profession :: Profession.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def update_profession(%Profession{} = profession, attrs),
    do:
      profession
      |> change_profession(attrs)
      |> versioning_update()
      |> broadcast("professions", :update)
      |> versioning_extract()

  @doc """
  Deletes a profession.

  ## Examples

      iex> delete_profession(profession)
      {:ok, %Profession{}}

      iex> delete_profession(profession)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_profession(profession :: Profession.t()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def delete_profession(%Profession{} = profession),
    do:
      profession
      |> change_profession
      |> versioning_delete()
      |> broadcast("professions", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profession changes.

  ## Examples

      iex> change_profession(profession)
      %Ecto.Changeset{data: %Profession{}}

  """

  @spec change_profession(
          tenant :: Profession.t() | Profession.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_profession(%Profession{} = profession, attrs \\ %{}),
    do: Profession.changeset(profession, attrs)

  @doc """
  Returns the list of people.

  ## Examples

      iex> list_people()
      [%Person{}, ...]

  """
  @spec list_people :: [Person.t()]
  def list_people, do: Repo.all(Person)

  @spec list_people(tenant :: Tenant.t()) :: [Person.t()]
  def list_people(tenant), do: tenant |> Ecto.assoc(:people) |> Repo.all()

  @doc """
  Gets a single person.

  Raises `Ecto.NoResultsError` if the Person does not exist.

  ## Examples

      iex> get_person!(123)
      %Person{}

      iex> get_person!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_person!(id :: String.t()) :: Person.t()
  def get_person!(id), do: Repo.get!(Person, id)

  @doc """
  Creates a person.

  ## Examples

      iex> create_person(%{field: value})
      {:ok, %Person{}}

      iex> create_person(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_person(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t()}
  def create_person(%Tenant{} = tenant, attrs \\ %{}),
    do:
      tenant
      |> Ecto.build_assoc(:people)
      |> change_person(attrs)
      |> versioning_insert()
      |> broadcast("people", :create)
      |> versioning_extract()

  @doc """
  Updates a person.

  ## Examples

      iex> update_person(person, %{field: new_value})
      {:ok, %Person{}}

      iex> update_person(person, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_person(person :: Person.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t()}
  def update_person(%Person{} = person, attrs),
    do:
      person
      |> change_person(attrs)
      |> versioning_update()
      |> broadcast("people", :update)
      |> versioning_extract()

  @doc """
  Deletes a person.

  ## Examples

      iex> delete_person(person)
      {:ok, %Person{}}

      iex> delete_person(person)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_person(person :: Person.t()) :: {:ok, Person.t()} | {:error, Ecto.Changeset.t()}
  def delete_person(%Person{} = person),
    do:
      person
      |> change_person()
      |> versioning_delete()
      |> broadcast("people", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking person changes.

  ## Examples

      iex> change_person(person)
      %Ecto.Changeset{data: %Person{}}

  """
  @spec change_person(
          person :: Person.t() | Person.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_person(%Person{} = person, attrs \\ %{}) do
    Person.changeset(person, attrs)
  end

  @doc """
  Returns the list of cases.

  ## Examples

      iex> list_cases()
      [%Case{}, ...]

  """
  @spec list_cases :: [Case.t()]
  def list_cases, do: Repo.all(Case)

  @doc """
  Gets a single case.

  Raises `Ecto.NoResultsError` if the Case does not exist.

  ## Examples

      iex> get_case!(123)
      %Case{}

      iex> get_case!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_case!(id :: String.t()) :: Case.t()
  def get_case!(id), do: Repo.get!(Case, id)

  @doc """
  Creates a case.

  ## Examples

      iex> create_case(%{field: value})
      {:ok, %Case{}}

      iex> create_case(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_case(person :: Person.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t()}
  def create_case(%Person{} = person, attrs \\ %{}) do
    tenant = Repo.preload(person, :tenant).tenant
    create_case(person, tenant, attrs)
  end

  @spec create_case(
          person :: Person.t(),
          tenant :: Tenant.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t()}
  def create_case(%Person{} = person, %Tenant{} = tenant, attrs),
    do:
      person
      |> Ecto.build_assoc(:cases)
      |> change_case(
        Map.put(
          attrs,
          case Enum.to_list(attrs) do
            [{key, _value} | _] when is_binary(key) -> "tenant_uuid"
            _other -> :tenant_uuid
          end,
          tenant.uuid
        )
      )
      |> versioning_insert()
      |> broadcast("cases", :create)
      |> versioning_extract()

  @doc """
  Updates a case.

  ## Examples

      iex> update_case(case, %{field: new_value})
      {:ok, %Case{}}

      iex> update_case(case, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_case(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t()}
  def update_case(%Case{} = case, attrs),
    do:
      case
      |> change_case(attrs)
      |> versioning_update()
      |> broadcast("cases", :update)
      |> versioning_extract()

  @doc """
  Deletes a case.

  ## Examples

      iex> delete_case(case)
      {:ok, %Case{}}

      iex> delete_case(case)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_case(case :: Case.t()) :: {:ok, Case.t()} | {:error, Ecto.Changeset.t()}
  def delete_case(%Case{} = case),
    do:
      case
      |> change_case()
      |> versioning_delete()
      |> broadcast("cases", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking case changes.

  ## Examples

      iex> change_case(case)
      %Ecto.Changeset{data: %Case{}}

  """
  @spec change_case(
          case :: Case.t() | Case.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_case(%Case{} = case, attrs \\ %{}), do: Case.changeset(case, attrs)
end
