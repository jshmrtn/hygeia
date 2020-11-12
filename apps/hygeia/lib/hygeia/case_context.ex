defmodule Hygeia.CaseContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ContactMethod
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Profession
  alias Hygeia.CaseContext.ProtocolEntry
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext.Tenant

  @sms_sender Application.compile_env!(:hygeia, [:sms_sender])

  @doc """
  Returns the list of professions.

  ## Examples

      iex> list_professions()
      [%Profession{}, ...]

  """
  @spec list_professions :: [Profession.t()]
  def list_professions, do: Repo.all(from profession in Profession, order_by: profession.name)

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
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t(Profession.t())}
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
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t(Profession.t())}
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
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t(Profession.t())}
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
          Ecto.Changeset.t(Profession.t())
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

  @spec list_people_query :: Ecto.Queryable.t()
  def list_people_query, do: Person

  @spec list_people(tenant :: Tenant.t()) :: [Person.t()]
  def list_people(tenant), do: tenant |> Ecto.assoc(:people) |> Repo.all()

  @spec list_people_by_contact_method(type :: ContactMethod.Type.t(), value :: String.t()) :: [
          Person.t()
        ]
  def list_people_by_contact_method(type, value),
    do:
      Repo.all(
        from(person in Person,
          where:
            fragment(
              ~S[?::jsonb <@ ANY (?)],
              ^%{type: type, value: value},
              person.contact_methods
            )
        )
      )

  @spec list_people_by_name(first_name :: String.t(), last_name :: String.t()) :: [Person.t()]
  def list_people_by_name(first_name, last_name),
    do:
      Repo.all(
        from(person in Person,
          where:
            fragment("SIMILARITY(?, ?) > 0.4", person.first_name, ^first_name) and
              fragment("SIMILARITY(?, ?) > 0.4", person.last_name, ^last_name)
        )
      )

  @spec fulltext_person_search(query :: String.t(), limit :: pos_integer()) :: [Person.t()]
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def fulltext_person_search(query, limit \\ 10),
    do:
      Repo.all(
        from(person in Person,
          left_join: contact_method in fragment("unnest(?)", person.contact_methods),
          left_join: external_reference in fragment("unnest(?)", person.external_references),
          left_join: employer in fragment("unnest(?)", person.employers),
          where:
            fragment("? % ?::text", ^query, person.uuid) or
              fragment("? % ?", ^query, person.human_readable_id) or
              fragment("? % ?", ^query, person.first_name) or
              fragment("? % ?", ^query, person.last_name) or
              fragment("? % (?->'value')::text", ^query, contact_method) or
              fragment("? % (?->'value')::text", ^query, external_reference) or
              fragment("? % (?->'address')::text", ^query, person.address) or
              fragment("? % (?->'zip')::text", ^query, person.address) or
              fragment("? % (?->'place')::text", ^query, person.address) or
              fragment("? % (?->'subdivision')::text", ^query, person.address) or
              fragment("? % (?->'country')::text", ^query, person.address) or
              fragment("? % (?->'name')::text", ^query, employer),
          group_by: person.uuid,
          limit: ^limit
        )
      )

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
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
  def create_person(%Tenant{} = tenant, attrs \\ %{}),
    do:
      tenant
      |> Ecto.build_assoc(:people)
      |> change_person(attrs)
      |> versioning_insert()
      |> broadcast("people", :create)
      |> versioning_extract()

  @spec person_has_mobile_number?(person :: Person.t()) :: boolean
  def person_has_mobile_number?(%Person{contact_methods: contact_methods} = _person),
    do: Enum.any?(contact_methods, &match?(%ContactMethod{type: :mobile}, &1))

  @doc """
  Updates a person.

  ## Examples

      iex> update_person(person, %{field: new_value})
      {:ok, %Person{}}

      iex> update_person(person, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_person(person :: Person.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
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
  @spec delete_person(person :: Person.t()) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
  def delete_person(%Person{} = person) do
    cases = Repo.preload(person, :cases).cases

    Repo.transaction(fn ->
      cases
      |> Enum.map(&delete_case/1)
      |> Enum.each(fn
        {:ok, _case} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end)

      person
      |> change_person()
      |> versioning_delete()
      |> broadcast("people", :delete)
      |> versioning_extract()
      |> case do
        {:ok, person} -> person
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

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
          Ecto.Changeset.t(Person.t())
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
  def list_cases, do: Repo.all(list_cases_query())

  @spec list_cases_query :: Ecto.Queryable.t()
  def list_cases_query, do: Case

  @spec fulltext_case_search(query :: String.t(), limit :: pos_integer()) :: [Case.t()]
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def fulltext_case_search(query, limit \\ 10),
    do:
      Repo.all(
        from(case in Case,
          join: person in assoc(case, :person),
          left_join: organisation in assoc(case, :related_organisations),
          left_join: case_external_reference in fragment("unnest(?)", case.external_references),
          left_join: person_contact_method in fragment("unnest(?)", person.contact_methods),
          left_join:
            person_external_reference in fragment("unnest(?)", person.external_references),
          where:
            fragment("? % ?::text", ^query, case.uuid) or
              fragment("? % ?", ^query, case.human_readable_id) or
              fragment("? % (?->'value')::text", ^query, case_external_reference) or
              fragment("? % ?::text", ^query, organisation.uuid) or
              fragment("? % ?", ^query, organisation.name) or
              fragment("? % (?->'address')::text", ^query, organisation.address) or
              fragment("? % (?->'zip')::text", ^query, organisation.address) or
              fragment("? % (?->'place')::text", ^query, organisation.address) or
              fragment("? % (?->'subdivision')::text", ^query, organisation.address) or
              fragment("? % (?->'country')::text", ^query, organisation.address) or
              fragment("? % ?::text", ^query, person.uuid) or
              fragment("? % ?", ^query, person.human_readable_id) or
              fragment("? % ?", ^query, person.first_name) or
              fragment("? % ?", ^query, person.last_name) or
              fragment("? % (?->'value')::text", ^query, person_contact_method) or
              fragment("? % (?->'value')::text", ^query, person_external_reference),
          group_by: case.uuid,
          limit: ^limit
        )
      )

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
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def create_case(%Person{} = person, attrs \\ %{}) do
    tenant = Repo.preload(person, :tenant).tenant
    create_case(person, tenant, attrs)
  end

  @spec create_case(
          person :: Person.t(),
          tenant :: Tenant.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
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

  @spec relate_case_to_organisation(case :: Case.t(), organisation :: Organisation.t()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def relate_case_to_organisation(case, organisation) do
    case = Repo.preload(case, :related_organisations)

    case
    |> change_case()
    |> Ecto.Changeset.put_assoc(:related_organisations, [
      organisation | case.related_organisations
    ])
    |> versioning_update()
    |> broadcast("cases", :update)
    |> versioning_extract()
  end

  @doc """
  Updates a case.

  ## Examples

      iex> update_case(case, %{field: new_value})
      {:ok, %Case{}}

      iex> update_case(case, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_case(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
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
  @spec delete_case(case :: Case.t()) :: {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def delete_case(%Case{} = case) do
    case = Repo.preload(case, protocol_entries: [], related_organisations: [])
    protocol_entries = case.protocol_entries

    Repo.transaction(fn ->
      protocol_entries
      |> Enum.map(&delete_protocol_entry/1)
      |> Enum.each(fn
        {:ok, _protocol_entry} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end)

      case =
        case
        |> change_case(%{related_organisations: []})
        |> versioning_update()
        |> broadcast("cases", :update)
        |> versioning_extract()
        |> case do
          {:ok, case} -> case
          {:error, reason} -> Repo.rollback(reason)
        end

      case
      |> versioning_delete()
      |> broadcast("cases", :delete)
      |> versioning_extract()
      |> case do
        {:ok, case} -> case
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec case_send_sms(case :: Case.t(), text :: String.t()) ::
          {:ok, ProtocolEntry.t()} | {:error, :no_mobile_number | term}
  def case_send_sms(%Case{} = case, text) do
    %Case{person: %Person{contact_methods: contact_methods} = person} =
      Repo.preload(case, :person)

    if person_has_mobile_number?(person) do
      phone_number =
        Enum.find_value(contact_methods, fn
          %{type: :mobile, value: value} -> value
          _contact_method -> false
        end)

      message_id = Ecto.UUID.generate()

      case @sms_sender.send(message_id, phone_number, text) do
        {:ok, delivery_receipt_id} ->
          create_protocol_entry(case, %{
            entry: %{__type__: "sms", text: text, delivery_receipt_id: delivery_receipt_id}
          })

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :no_mobile_number}
    end
  end

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
          Ecto.Changeset.t(Case.t())
  def change_case(%Case{} = case, attrs \\ %{}), do: Case.changeset(case, attrs)

  @doc """
  Returns the list of transmissions.

  ## Examples

      iex> list_transmissions()
      [%Transmission{}, ...]

  """
  @spec list_transmissions :: [Transmission.t()]
  def list_transmissions, do: Repo.all(Transmission)

  @doc """
  Gets a single transmission.

  Raises `Ecto.NoResultsError` if the Transmission does not exist.

  ## Examples

      iex> get_transmission!(123)
      %Transmission{}

      iex> get_transmission!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_transmission!(id :: String.t()) :: Transmission.t()
  def get_transmission!(id), do: Repo.get!(Transmission, id)

  @doc """
  Creates a transmission.

  ## Examples

      iex> create_transmission(%{field: value})
      {:ok, %Transmission{}}

      iex> create_transmission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_transmission(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Transmission.t()} | {:error, Ecto.Changeset.t(Transmission.t())}
  def create_transmission(attrs \\ %{}),
    do:
      %Transmission{}
      |> change_transmission(attrs)
      |> versioning_insert()
      |> broadcast(
        "transmissions",
        :create,
        & &1.uuid,
        &["cases:#{&1.recipient_case_uuid}", "cases:#{&1.propagator_case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Updates a transmission.

  ## Examples

      iex> update_transmission(transmission, %{field: new_value})
      {:ok, %Transmission{}}

      iex> update_transmission(transmission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_transmission(
          transmission :: Transmission.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, Transmission.t()} | {:error, Ecto.Changeset.t(Transmission.t())}
  def update_transmission(%Transmission{} = transmission, attrs),
    do:
      transmission
      |> change_transmission(attrs)
      |> versioning_update()
      |> broadcast(
        "transmissions",
        :update,
        & &1.uuid,
        &["cases:#{&1.recipient_case_uuid}", "cases:#{&1.propagator_case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Deletes a transmission.

  ## Examples

      iex> delete_transmission(transmission)
      {:ok, %Transmission{}}

      iex> delete_transmission(transmission)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_transmission(transmission :: Transmission.t()) ::
          {:ok, Transmission.t()} | {:error, Ecto.Changeset.t(Transmission.t())}
  def delete_transmission(%Transmission{} = transmission),
    do:
      transmission
      |> change_transmission()
      |> versioning_delete()
      |> broadcast(
        "transmissions",
        :delete,
        & &1.uuid,
        &["cases:#{&1.recipient_case_uuid}", "cases:#{&1.propagator_case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transmission changes.

  ## Examples

      iex> change_transmission(transmission)
      %Ecto.Changeset{data: %Transmission{}}

  """
  @spec change_transmission(
          tenant :: Transmission.t() | Transmission.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Transmission.t())
  def change_transmission(%Transmission{} = transmission, attrs \\ %{}),
    do: Transmission.changeset(transmission, attrs)

  @doc """
  Returns the list of protocol_entries.

  ## Examples

      iex> list_protocol_entries()
      [%ProtocolEntry{}, ...]

  """
  @spec list_protocol_entries :: [ProtocolEntry.t()]
  def list_protocol_entries, do: Repo.all(ProtocolEntry)

  @doc """
  Gets a single protocol_entry.

  Raises `Ecto.NoResultsError` if the Protocol entry does not exist.

  ## Examples

      iex> get_protocol_entry!(123)
      %ProtocolEntry{}

      iex> get_protocol_entry!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_protocol_entry!(id :: String.t()) :: ProtocolEntry.t()
  def get_protocol_entry!(id), do: Repo.get!(ProtocolEntry, id)

  @doc """
  Creates a protocol_entry.

  ## Examples

      iex> create_protocol_entry(%{field: value})
      {:ok, %ProtocolEntry{}}

      iex> create_protocol_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_protocol_entry(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, ProtocolEntry.t()} | {:error, Ecto.Changeset.t(ProtocolEntry.t())}
  def create_protocol_entry(%Case{} = case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:protocol_entries)
      |> change_protocol_entry(attrs)
      |> versioning_insert()
      |> broadcast(
        "protocol_entries",
        :create,
        & &1.uuid,
        &["protocol_entries:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Updates a protocol_entry.

  ## Examples

      iex> update_protocol_entry(protocol_entry, %{field: new_value})
      {:ok, %ProtocolEntry{}}

      iex> update_protocol_entry(protocol_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_protocol_entry(
          protocol_entry :: ProtocolEntry.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, ProtocolEntry.t()} | {:error, Ecto.Changeset.t(ProtocolEntry.t())}
  def update_protocol_entry(%ProtocolEntry{} = protocol_entry, attrs),
    do:
      protocol_entry
      |> change_protocol_entry(attrs)
      |> versioning_update()
      |> broadcast(
        "protocol_entries",
        :update,
        & &1.uuid,
        &["protocol_entries:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Deletes a protocol_entry.

  ## Examples

      iex> delete_protocol_entry(protocol_entry)
      {:ok, %ProtocolEntry{}}

      iex> delete_protocol_entry(protocol_entry)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_protocol_entry(protocol_entry :: ProtocolEntry.t()) ::
          {:ok, ProtocolEntry.t()} | {:error, Ecto.Changeset.t(ProtocolEntry.t())}
  def delete_protocol_entry(%ProtocolEntry{} = protocol_entry),
    do:
      protocol_entry
      |> change_protocol_entry()
      |> versioning_delete()
      |> broadcast(
        "protocol_entries",
        :delete,
        & &1.uuid,
        &["protocol_entries:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking protocol_entry changes.

  ## Examples

      iex> change_protocol_entry(protocol_entry)
      %Ecto.Changeset{data: %ProtocolEntry{}}

  """
  @spec change_protocol_entry(
          protocol_entry :: ProtocolEntry.t() | ProtocolEntry.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(ProtocolEntry.t())
  def change_protocol_entry(%ProtocolEntry{} = protocol_entry, attrs \\ %{}),
    do: ProtocolEntry.changeset(protocol_entry, attrs)
end
