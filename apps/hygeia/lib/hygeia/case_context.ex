defmodule Hygeia.CaseContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.ProtocolEntry
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.EmailSender.Smtp
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.TenantContext.Websms

  @sms_sender Application.compile_env!(:hygeia, [:sms_sender])
  @origin_country Application.compile_env!(:hygeia, [:phone_number_parsing_origin_country])

  @doc """
  Returns the list of people.

  ## Examples

      iex> list_people()
      [%Person{}, ...]

  """
  @spec list_people(limit :: pos_integer()) :: [Person.t()]
  def list_people(limit \\ 20), do: Repo.all(from(person in Person, limit: ^limit))

  @spec list_people_by_ids(ids :: [String.t()]) :: [Person.t()]
  def list_people_by_ids(ids), do: Repo.all(from(person in Person, where: person.uuid in ^ids))

  @spec list_people_query :: Ecto.Queryable.t()
  def list_people_query, do: Person

  @spec find_duplicates(
          search :: [
            %{
              uuid: String.t(),
              first_name: String.t() | nil,
              last_name: String.t(),
              mobile: String.t() | nil,
              email: String.t() | nil
            }
          ]
        ) :: %{required(uuid :: String.t()) => [person_id :: String.t()]}
  def find_duplicates([]), do: %{}

  def find_duplicates(search) when is_list(search) do
    "search"
    |> with_cte("search",
      as:
        fragment(
          """
          SELECT search->>'uuid' AS uuid, duplicate.uuid AS person_uuid
          FROM JSONB_ARRAY_ELEMENTS(?::jsonb) AS search
          LEFT JOIN people AS duplicate ON
              (
                  duplicate.first_name % (search->>'first_name')::text AND
                  duplicate.last_name % (search->>'last_name')::text
              ) OR
              JSONB_BUILD_OBJECT('type', 'mobile', 'value', search->>'mobile') <@ ANY (duplicate.contact_methods) OR
              JSONB_BUILD_OBJECT('type', 'landline', 'value', search->>'landline') <@ ANY (duplicate.contact_methods) OR
              JSONB_BUILD_OBJECT('type', 'email', 'value', search->>'email') <@ ANY (duplicate.contact_methods)
          GROUP BY search->>'uuid', duplicate.uuid
          """,
          ^search
        )
    )
    |> select([s], {type(s.uuid, Ecto.UUID), type(s.person_uuid, Ecto.UUID)})
    |> Repo.all()
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {key, duplicates} ->
      {key, Enum.reject(duplicates, &is_nil/1)}
    end)
  end

  @spec list_people_by_contact_method(type :: ContactMethod.Type.t(), value :: String.t()) :: [
          Person.t()
        ]

  def list_people_by_contact_method(type, value) when type in [:mobile, :landline] do
    with {:ok, parsed_number} <-
           ExPhoneNumber.parse(value, @origin_country),
         true <- ExPhoneNumber.is_valid_number?(parsed_number) do
      _list_people_by_contact_method(
        type,
        ExPhoneNumber.Formatting.format(parsed_number, :international)
      )
    else
      false -> []
      {:error, _reason} -> []
    end
  end

  def list_people_by_contact_method(type, value), do: _list_people_by_contact_method(type, value)

  defp _list_people_by_contact_method(type, value),
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
            fragment("(? % ?)", person.first_name, ^first_name) and
              fragment("(? % ?)", person.last_name, ^last_name),
          order_by: [
            asc:
              fragment("(? <-> ?)", person.first_name, ^first_name) +
                fragment("(? <-> ?)", person.last_name, ^last_name)
          ]
        )
      )

  @spec fulltext_person_search(query :: String.t(), limit :: pos_integer()) :: [Person.t()]
  def fulltext_person_search(query, limit \\ 10),
    do: Repo.all(fulltext_person_search_query(query, limit))

  @spec fulltext_person_search_query(query :: String.t(), limit :: pos_integer()) ::
          Ecto.Query.t()
  def fulltext_person_search_query(query, limit \\ 10),
    do:
      from(person in Person,
        where: fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", person, ^query),
        order_by: [
          desc:
            fragment(
              "TS_RANK_CD(?.fulltext, WEBSEARCH_TO_TSQUERY('german', ?))",
              person,
              ^query
            )
        ],
        limit: ^limit
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
  def create_person(%Tenant{} = tenant, attrs),
    do:
      tenant
      |> create_person_changeset(attrs)
      |> create_person()

  @spec create_person(changeset :: Ecto.Changeset.t(Person.t())) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
  def create_person(%Ecto.Changeset{data: %Person{}} = changeset),
    do:
      changeset
      |> Person.changeset(%{})
      |> versioning_insert()
      |> broadcast("people", :create)
      |> versioning_extract()

  @spec person_has_mobile_number?(person :: Person.t()) :: boolean
  def person_has_mobile_number?(%Person{contact_methods: contact_methods} = _person),
    do: Enum.any?(contact_methods, &match?(%ContactMethod{type: :mobile}, &1))

  @spec person_has_email?(person :: Person.t()) :: boolean
  def person_has_email?(%Person{contact_methods: contact_methods} = _person),
    do: Enum.any?(contact_methods, &match?(%ContactMethod{type: :email}, &1))

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
      |> update_person()

  @spec update_person(changeset :: Ecto.Changeset.t(Person.t())) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
  def update_person(%Ecto.Changeset{data: %Person{}} = changeset),
    do:
      changeset
      |> Person.changeset(%{})
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

  @spec create_person_changeset(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Person.t())
  def create_person_changeset(tenant, attrs \\ %{}) do
    tenant
    |> Ecto.build_assoc(:people)
    |> change_person(attrs)
  end

  @doc """
  Returns the list of cases.

  ## Examples

      iex> list_cases()
      [%Case{}, ...]

  """
  @spec list_cases(limit :: pos_integer()) :: [Case.t()]
  def list_cases(limit \\ 20), do: Repo.all(from(c in list_cases_query(), limit: ^limit))

  @spec list_cases_query :: Ecto.Queryable.t()
  def list_cases_query, do: Case

  @spec list_cases_for_automated_closed_email :: [{Case.t(), Case.Phase.t()}]
  def list_cases_for_automated_closed_email do
    from(case in Case,
      join: phase in fragment("UNNEST(?)", case.phases),
      where:
        fragment("(?->>'end')::date", phase) <= fragment("CURRENT_DATE") and
          fragment("(?->'send_automated_close_email')::boolean", phase) and
          is_nil(fragment("?->>'automated_close_email_sent'", phase)),
      select: {case, fragment("(?->>'uuid')::uuid", phase)},
      lock: "FOR UPDATE"
    )
    |> Repo.all()
    |> Enum.map(fn {%Case{phases: phases} = case, phase_binary_uuid} ->
      phase_uuid = Ecto.UUID.cast!(phase_binary_uuid)
      {case, Enum.find(phases, &match?(%Case.Phase{uuid: ^phase_uuid}, &1))}
    end)
  end

  @spec fulltext_case_search(query :: String.t(), limit :: pos_integer()) :: [Case.t()]
  def fulltext_case_search(query, limit \\ 10),
    do: Repo.all(fulltext_case_search_query(query, limit))

  @spec fulltext_case_search_query(query :: String.t(), limit :: pos_integer()) :: Ecto.Query.t()
  def fulltext_case_search_query(query, limit \\ 10),
    do:
      from(case in Case,
        join: person in assoc(case, :person),
        left_join: organisation in assoc(case, :related_organisations),
        where:
          fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", person, ^query) or
            fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", case, ^query) or
            fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", organisation, ^query),
        order_by: [
          desc:
            max(
              fragment(
                "TS_RANK_CD((?.fulltext || ?.fulltext || ?.fulltext), WEBSEARCH_TO_TSQUERY('german', ?))",
                case,
                person,
                organisation,
                ^query
              )
            )
        ],
        group_by: case.uuid,
        limit: ^limit
      )

  @bag_med_16122020_case_fields [
    :fall_id_ism,
    :ktn_internal_id,
    :last_name,
    :first_name,
    :street_name,
    :street_number,
    :location,
    :postal_code,
    :country,
    :phone_number,
    :mobile_number,
    :e_mail_address,
    :sex,
    :date_of_birth,
    :profession,
    :work_place_name,
    :work_place_street,
    :work_place_street_number,
    :work_place_location,
    :work_place_postal_code,
    :work_place_country,
    :symptoms_yn,
    :test_reason_symptoms,
    :test_reason_outbreak,
    :test_reason_cohort,
    :test_reason_work_screening,
    :test_reason_quarantine,
    :test_reason_app,
    :test_reason_convenience,
    :symptom_onset_dt,
    :sampling_dt,
    :lab_report_dt,
    :test_type,
    :test_result,
    :exp_type,
    :case_link_yn,
    :case_link_contact_dt,
    :case_link_fall_id_ism,
    :case_link_ktn_internal_id,
    :exp_loc_dt,
    :exp_loc_type_yn,
    :activity_mapping_yn,
    :exp_country,
    :exp_loc_type_work_place,
    :exp_loc_type_army,
    :exp_loc_type_asyl,
    :exp_loc_type_choir,
    :exp_loc_type_club,
    :exp_loc_type_hh,
    :exp_loc_type_high_school,
    :exp_loc_type_childcare,
    :exp_loc_type_erotica,
    :exp_loc_type_flight,
    :exp_loc_type_medical,
    :exp_loc_type_hotel,
    :exp_loc_type_child_home,
    :exp_loc_type_cinema,
    :exp_loc_type_shop,
    :exp_loc_type_school,
    :exp_loc_type_less_300,
    :exp_loc_type_more_300,
    :exp_loc_type_public_transp,
    :exp_loc_type_massage,
    :exp_loc_type_nursing_home,
    :exp_loc_type_religion,
    :exp_loc_type_restaurant,
    :exp_loc_type_school_camp,
    :exp_loc_type_indoor_sport,
    :exp_loc_type_outdoor_sport,
    :exp_loc_type_gathering,
    :exp_loc_type_zoo,
    :exp_loc_type_prison,
    :other_exp_loc_type,
    :exp_loc_type_less_300_detail,
    :exp_loc_type_more_300_detail,
    :exp_loc_name,
    :exp_loc_street,
    :exp_loc_street_number,
    :exp_loc_location,
    :exp_loc_postal_code,
    :exp_loc_flightdetail,
    :corr_ct_dt,
    :quar_yn,
    :onset_quar_dt,
    :reason_quar,
    :other_reason_quar,
    :onset_iso_dt,
    :iso_loc_type,
    :other_iso_loc,
    :iso_loc_street,
    :iso_loc_street_number,
    :iso_loc_location,
    :iso_loc_postal_code,
    :iso_loc_country,
    :follow_up_dt,
    :end_of_iso_dt,
    :reason_end_of_iso,
    :other_reason_end_of_iso,
    :vacc_yn,
    :vacc_name,
    :vacc_dose,
    :vacc_dt_first,
    :vacc_dt_last
  ]

  @bag_med_16122020_case_fields_index @bag_med_16122020_case_fields
                                      |> Enum.with_index()
                                      |> Map.new()

  @spec case_export(tenant :: Tenant.t(), format :: :bag_med_16122020_case) :: Enumerable.t()
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def case_export(%Tenant{uuid: tenant_uuid} = _teant, :bag_med_16122020_case) do
    first_transmission_query =
      from(transmission in Transmission,
        select: %{
          uuid:
            fragment(
              """
              FIRST_VALUE(?)
              OVER(
                PARTITION BY ?
                ORDER BY ?
              )
              """,
              transmission.uuid,
              transmission.recipient_case_uuid,
              transmission.inserted_at
            ),
          case_uuid: transmission.recipient_case_uuid
        }
      )

    cases =
      from(case in Case,
        join: phase in fragment("UNNEST(?)", case.phases),
        left_join: case_ism_id in fragment("UNNEST(?)", case.external_references),
        on: fragment("?->>'type'", case_ism_id) == "ism_case",
        left_join: possible_index_phase in fragment("UNNEST(?)", case.phases),
        on:
          fragment("?->'details'->>'__type__'", possible_index_phase) ==
            "possible_index",
        left_join: index_phase in fragment("UNNEST(?)", case.phases),
        on:
          fragment("?->'details'->>'__type__'", index_phase) ==
            "index",
        left_join: possible_index_phase_contact_person in fragment("UNNEST(?)", case.phases),
        on:
          fragment("?->'details'->>'__type__'", possible_index_phase_contact_person) ==
            "possible_index" and
            fragment("?->'details'->>'type'", possible_index_phase_contact_person) ==
              "contact_person",
        left_join: possible_index_phase_travel in fragment("UNNEST(?)", case.phases),
        on:
          fragment("?->'details'->>'__type__'", possible_index_phase_travel) == "possible_index" and
            fragment("?->'details'->>'type'", possible_index_phase_travel) == "travel",
        join: person in assoc(case, :person),
        left_join: mobile_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>'type'", mobile_contact_method) == "mobile",
        left_join: landline_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>'type'", landline_contact_method) == "landline",
        left_join: email_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>'type'", email_contact_method) == "email",
        left_join: received_transmission_id in subquery(first_transmission_query),
        on: received_transmission_id.case_uuid == case.uuid,
        left_join: received_transmission in assoc(case, :received_transmissions),
        on: received_transmission.uuid == received_transmission_id.uuid,
        left_join: received_transmission_case in assoc(received_transmission, :propagator_case),
        left_join:
          received_transmission_case_ism_id in fragment(
            "UNNEST(?)",
            received_transmission_case.external_references
          ),
        on: fragment("?->>'type'", received_transmission_case_ism_id) == "ism_case",
        left_join: protocol_entry in assoc(case, :protocol_entries),
        where:
          case.tenant_uuid == ^tenant_uuid and
            fragment("?->'details'->>'__type__'", phase) == "index",
        group_by: [case.uuid, person.uuid],
        order_by: [asc: case.inserted_at],
        select: [
          # fall_id_ism
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'value'", case_ism_id)),
          # ktn_internal_id
          type(case.uuid, Ecto.UUID),
          # last_name
          person.last_name,
          # first_name
          person.first_name,
          # street_name
          fragment("?->>'address'", person.address),
          # street_number
          nil,
          # location
          fragment("?->>'place'", person.address),
          # postal_code
          fragment("?->>'zip'", person.address),
          # country
          fragment("?->>'country'", person.address),
          # phone_number
          max(fragment("?->>'value'", landline_contact_method)),
          # mobile_number
          max(fragment("?->>'value'", mobile_contact_method)),
          # e_mail_address
          max(fragment("?->>'value'", email_contact_method)),
          # sex
          person.sex,
          # date_of_birth
          person.birth_date,
          # profession
          person.profession_category_main,
          # work_place_name
          fragment("?[1]->>'name'", person.employers),
          # work_place_street
          fragment("?[1]->'address'->>'address'", person.employers),
          # work_place_street_number
          nil,
          # work_place_location
          fragment("?[1]->'address'->>'place'", person.employers),
          # work_place_postal_code
          fragment("?[1]->'address'->>'zip'", person.employers),
          # work_place_country
          fragment("?[1]->'address'->>'country'", person.employers),
          # symptoms_yn
          fragment("?->'has_symptoms'", case.clinical),
          # test_reason_symptoms
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "symptoms"),
          # test_reason_outbreak
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "outbreak_examination"),
          # test_reason_cohort
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "screening"),
          # test_reason_work_screening
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "work_related"),
          # test_reason_quarantine
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "quarantine"),
          # test_reason_app
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "app_report"),
          # test_reason_convenience
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "convenience"),
          # symptom_onset_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", phase)),
          # sampling_dt
          fragment("?->>'test'", case.clinical),
          # lab_report_dt
          fragment("(?->>'laboratory_report')", case.clinical),
          # test_type
          type(fragment("(?->>'test_kind')", case.clinical), Case.Clinical.TestKind),
          # test_result
          type(fragment("(?->>'result')", case.clinical), Case.Clinical.Result),
          # exp_type
          type(
            fragment(
              """
              CASE
                WHEN ? THEN ?
                WHEN ? THEN ?
              END
              """,
              count(fragment("?->>'uuid'", possible_index_phase_contact_person), :distinct) > 0,
              "contact_person",
              count(fragment("?->>'uuid'", possible_index_phase_travel), :distinct) > 0,
              "travel"
            ),
            Case.Phase.PossibleIndex.Type
          ),
          # case_link_yn
          count(received_transmission.uuid) > 0,
          # case_link_contact_dt
          fragment("(ARRAY_AGG(?))[1]", received_transmission.date),
          # case_link_fall_id_ism
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment(
              """
              CASE
                WHEN ? THEN ?
                WHEN ? THEN ?
              END
              """,
              not received_transmission.propagator_internal,
              received_transmission.propagator_ism_id,
              received_transmission.propagator_internal,
              fragment("?->>'value'", received_transmission_case_ism_id)
            )
          ),
          # case_link_ktn_internal_id
          type(
            fragment("(ARRAY_AGG(?))[1]", received_transmission.propagator_case_uuid),
            Ecto.UUID
          ),
          # exp_loc_dt
          fragment("(ARRAY_AGG(?))[1]", received_transmission.date),
          # exp_loc_type_yn
          fragment("(ARRAY_AGG(?->>'known'))[1]", received_transmission.infection_place),
          # activity_mapping_yn
          nil,
          # exp_country
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment("?->'address'->'country'", received_transmission.infection_place)
          ),
          # exp_loc_type_work_place
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "work_place"
          ),
          # exp_loc_type_army
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "army"
          ),
          # exp_loc_type_asyl
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "asyl"
          ),
          # exp_loc_type_choir
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "choir"
          ),
          # exp_loc_type_club
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "club"
          ),
          # exp_loc_type_hh
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "hh"
          ),
          # exp_loc_type_high_school
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "high_school"
          ),
          # exp_loc_type_childcare
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "childcare"
          ),
          # exp_loc_type_erotica
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "erotica"
          ),
          # exp_loc_type_flight
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "flight"
          ),
          # exp_loc_type_medical
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "medical"
          ),
          # exp_loc_type_hotel
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "hotel"
          ),
          # exp_loc_type_child_home
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "child_home"
          ),
          # exp_loc_type_cinema
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "cinema"
          ),
          # exp_loc_type_shop
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "shop"
          ),
          # exp_loc_type_school
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "school"
          ),
          # exp_loc_type_less_300
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "less_300"
          ),
          # exp_loc_type_more_300
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "more_300"
          ),
          # exp_loc_type_public_transp
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "public_transp"
          ),
          # exp_loc_type_massage
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "massage"
          ),
          # exp_loc_type_nursing_home
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "nursing_home"
          ),
          # exp_loc_type_religion
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "religion"
          ),
          # exp_loc_type_restaurant
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "restaurant"
          ),
          # exp_loc_type_school_camp
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "school_camp"
          ),
          # exp_loc_type_indoor_sport
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "indoor_sport"
          ),
          # exp_loc_type_outdoor_sport
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "outdoor_sport"
          ),
          # exp_loc_type_gathering
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "gathering"
          ),
          # exp_loc_type_zoo
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "zoo"
          ),
          # exp_loc_type_prison
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "prison"
          ),
          # other_exp_loc_type
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "other"
          ),
          # exp_loc_type_less_300_detail
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_type_more_300_detail
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_name
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_street
          fragment(
            "(ARRAY_AGG(?->'address'->'address'))[1]",
            received_transmission.infection_place
          ),
          # exp_loc_street_number
          nil,
          # exp_loc_location
          fragment(
            "(ARRAY_AGG(?->'address'->>'place'))[1]",
            received_transmission.infection_place
          ),
          # exp_loc_postal_code
          fragment("(ARRAY_AGG(?->'address'->>'zip'))[1]", received_transmission.infection_place),
          # exp_loc_flightdetail
          fragment(
            "(ARRAY_AGG(?->>'flight_information'))[1]",
            received_transmission.infection_place
          ),
          # corr_ct_dt
          # TODO: Where to find first contact date?
          nil,
          # quar_yn
          count(fragment("?->>'uuid'", possible_index_phase), :distinct) > 0,
          # onset_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", possible_index_phase)),
          # reason_quar
          # TODO: Where to get the values apart contact & travel?
          nil,
          # other_reason_quar
          # TODO: Where to get the values apart contact & travel?
          nil,
          # onset_iso_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", index_phase)),
          # iso_loc_type
          type(
            fragment("(?->>'location')::isolation_location", case.monitoring),
            Case.Monitoring.IsolationLocation
          ),
          # other_iso_loc
          fragment("?->>'location_details'", case.monitoring),
          # iso_loc_street
          fragment("?->'address'->>'address'", case.monitoring),
          # iso_loc_street_number
          nil,
          # iso_loc_location
          fragment("?->'address'->>'place'", case.monitoring),
          # iso_loc_postal_code
          fragment("?->'address'->>'zip'", case.monitoring),
          # iso_loc_country
          fragment("?->'address'->>'country'", case.monitoring),
          # follow_up_dt
          fragment("(?)::date", max(protocol_entry.inserted_at)),
          # end_of_iso_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'end'", index_phase)),
          # reason_end_of_iso
          # TODO: Allow other
          fragment("(ARRAY_AGG(?))[1]", fragment("?->'detail'->>'end_reason'", index_phase)),
          # other_reason_end_of_iso
          # TODO: Text Field when other
          nil,
          # vacc_yn
          fragment("(?->>'done')::boolean", person.vaccination),
          # vacc_name
          fragment("?->>'name'", person.vaccination),
          # vacc_dose
          fragment("JSONB_ARRAY_LENGTH(?->'jab_dates')", person.vaccination),
          # vacc_dt_first
          fragment("(?->'jab_dates'->>0)", person.vaccination),
          # vacc_dt_last
          fragment("(?->'jab_dates'->>-1)", person.vaccination)
        ]
      )
      |> Repo.stream()
      |> Stream.map(fn entry ->
        entry
        |> List.update_at(@bag_med_16122020_case_fields_index.phone_number, fn
          nil ->
            nil

          phone_number ->
            {:ok, parsed_number} = ExPhoneNumber.parse(phone_number, @origin_country)
            ExPhoneNumber.Formatting.format(parsed_number, :e164)
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.mobile_number, fn
          nil ->
            nil

          phone_number ->
            {:ok, parsed_number} = ExPhoneNumber.parse(phone_number, @origin_country)
            ExPhoneNumber.Formatting.format(parsed_number, :e164)
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.sex, fn
          nil -> nil
          :male -> 1
          :female -> 2
          :other -> 3
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.iso_loc_type, fn
          nil -> 6
          :home -> 1
          :social_medical_facility -> 2
          :hospital -> 3
          :hotel -> 4
          :asylum_center -> 5
          :other -> 7
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_type, fn
          nil -> nil
          :contact_person -> 1
          :travel -> 2
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_symptoms, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_outbreak, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_cohort, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_work_screening, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_quarantine, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_app, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_reason_convenience, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_work_place, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_army, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_asyl, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_choir, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_club, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_hh, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_high_school, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_childcare, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_erotica, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_flight, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_medical, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_hotel, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_child_home, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_cinema, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_shop, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_school, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_less_300, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_more_300, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_public_transp, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_massage, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_nursing_home, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_religion, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_restaurant, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_school_camp, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_indoor_sport, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_outdoor_sport, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_gathering, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_zoo, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.exp_loc_type_prison, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.other_exp_loc_type, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_type, fn
          nil -> 5
          :pcr -> 1
          :serology -> 5
          :quick -> 2
          :antigen_quick -> 3
          :antigen -> 4
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.test_result, fn
          :positive -> 1
          :negative -> 2
          nil -> 3
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.reason_end_of_iso, fn
          # :other -> 4
          nil -> nil
          :healed -> 1
          :death -> 2
          :no_follow_up -> 3
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.vacc_yn, fn
          true -> 1
          false -> 2
          nil -> 3
        end)
      end)

    [@bag_med_16122020_case_fields]
    |> Stream.concat(cases)
    |> CSV.encode()
  end

  @bag_med_16122020_contact_fields [
    :ktn_internal_id,
    :last_name,
    :first_name,
    :street_name,
    :street_number,
    :location,
    :postal_code,
    :country,
    :phone_number,
    :mobile_number,
    :sex,
    :date_of_birth,
    :profession,
    :work_place_name,
    :work_place_postal_code,
    :work_place_country,
    :quar_loc_type,
    :other_quar_loc_type,
    :exp_type,
    :case_link_fall_id_ism,
    :case_link_ktn_internal_id,
    :case_link_contact_dt,
    :exp_loc_dt,
    :exp_country,
    :exp_loc_type_work_place,
    :exp_loc_type_army,
    :exp_loc_type_asyl,
    :exp_loc_type_choir,
    :exp_loc_type_club,
    :exp_loc_type_hh,
    :exp_loc_type_high_school,
    :exp_loc_type_childcare,
    :exp_loc_type_erotica,
    :exp_loc_type_flight,
    :exp_loc_type_medical,
    :exp_loc_type_hotel,
    :exp_loc_type_child_home,
    :exp_loc_type_cinema,
    :exp_loc_type_shop,
    :exp_loc_type_school,
    :exp_loc_type_less_300,
    :exp_loc_type_more_300,
    :exp_loc_type_public_transp,
    :exp_loc_type_massage,
    :exp_loc_type_nursing_home,
    :exp_loc_type_religion,
    :exp_loc_type_restaurant,
    :exp_loc_type_school_camp,
    :exp_loc_type_indoor_sport,
    :exp_loc_type_outdoor_sport,
    :exp_loc_type_gathering,
    :exp_loc_type_zoo,
    :exp_loc_type_prison,
    :other_exp_loc_type,
    :exp_loc_type_less_300_detail,
    :exp_loc_type_more_300_detail,
    :exp_loc_name,
    :exp_loc_street,
    :exp_loc_street_number,
    :exp_loc_location,
    :exp_loc_postal_code,
    :exp_loc_flightdetail,
    :test_reason_symptoms,
    :test_reason_quarantine,
    :test_reason_quarantine_end,
    :other_test_reason,
    :symptom_onset_dt,
    :test_type,
    :sampling_dt,
    :test_result,
    :onset_quar_dt,
    :end_quar_dt,
    :reason_end_quar,
    :other_reason_end_quar,
    :vacc_yn,
    :vacc_name,
    :vacc_dose,
    :vacc_dt_first,
    :vacc_dt_last
  ]

  @bag_med_16122020_contact_fields_index @bag_med_16122020_contact_fields
                                         |> Enum.with_index()
                                         |> Map.new()

  @spec case_export(tenant :: Tenant.t(), format :: :bag_med_16122020_contact) :: Enumerable.t()
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def case_export(%Tenant{uuid: tenant_uuid} = _teant, :bag_med_16122020_contact) do
    first_transmission_query =
      from(transmission in Transmission,
        select: %{
          uuid:
            fragment(
              """
              FIRST_VALUE(?)
              OVER(
                PARTITION BY ?
                ORDER BY ?
              )
              """,
              transmission.uuid,
              transmission.recipient_case_uuid,
              transmission.inserted_at
            ),
          case_uuid: transmission.recipient_case_uuid
        }
      )

    cases =
      from(case in Case,
        join: phase in fragment("UNNEST(?)", case.phases),
        left_join: phase_index in fragment("UNNEST(?)", case.phases),
        on: fragment("?->'details'->>'__type__'", phase_index) == "index",
        join: person in assoc(case, :person),
        left_join: mobile_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>'type'", mobile_contact_method) == "mobile",
        left_join: landline_contact_method in fragment("UNNEST(?)", person.contact_methods),
        on: fragment("?->>'type'", landline_contact_method) == "landline",
        left_join: received_transmission_id in subquery(first_transmission_query),
        on: received_transmission_id.case_uuid == case.uuid,
        left_join: received_transmission in assoc(case, :received_transmissions),
        on: received_transmission.uuid == received_transmission_id.uuid,
        left_join: received_transmission_case in assoc(received_transmission, :propagator_case),
        left_join:
          received_transmission_case_ism_id in fragment(
            "UNNEST(?)",
            received_transmission_case.external_references
          ),
        on: fragment("?->>'type'", received_transmission_case_ism_id) == "ism_case",
        where:
          case.tenant_uuid == ^tenant_uuid and
            fragment("?->'details'->>'__type__'", phase) == "possible_index",
        group_by: [case.uuid, person.uuid],
        order_by: [asc: case.inserted_at],
        select: [
          # ktn_internal_id
          type(case.uuid, Ecto.UUID),
          # last_name
          person.last_name,
          # first_name
          person.first_name,
          # street_name
          fragment("?->>'address'", person.address),
          # street_number
          nil,
          # location
          fragment("?->>'place'", person.address),
          # postal_code
          fragment("?->>'zip'", person.address),
          # country
          fragment("?->>'country'", person.address),
          # phone_number
          max(fragment("?->>'value'", landline_contact_method)),
          # mobile_number
          max(fragment("?->>'value'", mobile_contact_method)),
          # sex
          person.sex,
          # date_of_birth
          person.birth_date,
          # profession
          person.profession_category_main,
          # work_place_name
          fragment("?[1]->>'name'", person.employers),
          # work_place_postal_code
          fragment("?[1]->'address'->>'zip'", person.employers),
          # work_place_country
          fragment("?[1]->'address'->>'country'", person.employers),
          # quar_loc_type
          type(
            fragment("(?->>'location')::isolation_location", case.monitoring),
            Case.Monitoring.IsolationLocation
          ),
          # other_quar_loc_type
          fragment("?->>'location_details'", case.monitoring),
          # exp_type
          type(
            fragment("(ARRAY_AGG(?))[1]", fragment("(?->'details'->>'type')", phase)),
            Case.Phase.PossibleIndex.Type
          ),
          # case_link_fall_id_ism
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment(
              """
              CASE
                WHEN ? THEN ?
                WHEN ? THEN ?
              END
              """,
              not received_transmission.propagator_internal,
              received_transmission.propagator_ism_id,
              received_transmission.propagator_internal,
              fragment("?->>'value'", received_transmission_case_ism_id)
            )
          ),
          # case_link_ktn_internal_id
          type(
            fragment("(ARRAY_AGG(?))[1]", received_transmission.propagator_case_uuid),
            Ecto.UUID
          ),
          # case_link_contact_dt
          fragment("(ARRAY_AGG(?))[1]", received_transmission.date),
          # exp_loc_dt
          fragment("(ARRAY_AGG(?))[1]", received_transmission.date),
          # exp_country
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment("?->'address'->'country'", received_transmission.infection_place)
          ),
          # exp_loc_type_work_place
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "work_place"
          ),
          # exp_loc_type_army
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "army"
          ),
          # exp_loc_type_asyl
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "asyl"
          ),
          # exp_loc_type_choir
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "choir"
          ),
          # exp_loc_type_club
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "club"
          ),
          # exp_loc_type_hh
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "hh"
          ),
          # exp_loc_type_high_school
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "high_school"
          ),
          # exp_loc_type_childcare
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "childcare"
          ),
          # exp_loc_type_erotica
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "erotica"
          ),
          # exp_loc_type_flight
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "flight"
          ),
          # exp_loc_type_medical
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "medical"
          ),
          # exp_loc_type_hotel
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "hotel"
          ),
          # exp_loc_type_child_home
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "child_home"
          ),
          # exp_loc_type_cinema
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "cinema"
          ),
          # exp_loc_type_shop
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "shop"
          ),
          # exp_loc_type_school
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "school"
          ),
          # exp_loc_type_less_300
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "less_300"
          ),
          # exp_loc_type_more_300
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "more_300"
          ),
          # exp_loc_type_public_transp
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "public_transp"
          ),
          # exp_loc_type_massage
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "massage"
          ),
          # exp_loc_type_nursing_home
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "nursing_home"
          ),
          # exp_loc_type_religion
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "religion"
          ),
          # exp_loc_type_restaurant
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "restaurant"
          ),
          # exp_loc_type_school_camp
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "school_camp"
          ),
          # exp_loc_type_indoor_sport
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "indoor_sport"
          ),
          # exp_loc_type_outdoor_sport
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "outdoor_sport"
          ),
          # exp_loc_type_gathering
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "gathering"
          ),
          # exp_loc_type_zoo
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "zoo"
          ),
          # exp_loc_type_prison
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "prison"
          ),
          # other_exp_loc_type
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "other"
          ),
          # exp_loc_type_less_300_detail
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_type_more_300_detail
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_name
          fragment("(ARRAY_AGG(?->>'name'))[1]", received_transmission.infection_place),
          # exp_loc_street
          fragment(
            "(ARRAY_AGG(?->'address'->'address'))[1]",
            received_transmission.infection_place
          ),
          # exp_loc_street_number
          nil,
          # exp_loc_location
          fragment(
            "(ARRAY_AGG(?->'address'->>'place'))[1]",
            received_transmission.infection_place
          ),
          # exp_loc_postal_code
          fragment("(ARRAY_AGG(?->'address'->>'zip'))[1]", received_transmission.infection_place),
          # exp_loc_flightdetail
          fragment(
            "(ARRAY_AGG(?->>'flight_information'))[1]",
            received_transmission.infection_place
          ),
          # test_reason_symptoms
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "symptoms"),
          # test_reason_quarantine
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "quarantine"),
          # test_reason_quarantine_end
          # TODO
          nil,
          # other_test_reason
          fragment("?->'reasons_for_test' \\?| ?", case.clinical, [
            "outbreak_examination",
            "screening",
            "work_related",
            "app_report",
            "contact_tracing",
            "convenience"
          ]),
          # symptom_onset_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", phase_index)),
          # test_type
          type(fragment("(?->>'test_kind')", case.clinical), Case.Clinical.TestKind),
          # sampling_dt
          fragment("?->>'test'", case.clinical),
          # test_result
          type(fragment("(?->>'result')", case.clinical), Case.Clinical.Result),
          # onset_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", phase)),
          # end_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'end'", phase)),
          # reason_end_quar
          fragment("(ARRAY_AGG(?))[1]", fragment("?->'detail'->>'end_reason'", phase)),
          # other_reason_end_quar
          # TODO
          nil,
          # vacc_yn
          fragment("(?->>'done')::boolean", person.vaccination),
          # vacc_name
          fragment("?->>'name'", person.vaccination),
          # vacc_dose
          fragment("JSONB_ARRAY_LENGTH(?->'jab_dates')", person.vaccination),
          # vacc_dt_first
          fragment("(?->'jab_dates'->>0)", person.vaccination),
          # vacc_dt_last
          fragment("(?->'jab_dates'->>-1)", person.vaccination)
        ]
      )
      |> Repo.stream()
      |> Stream.map(fn entry ->
        entry
        |> List.update_at(@bag_med_16122020_contact_fields_index.phone_number, fn
          nil ->
            nil

          phone_number ->
            {:ok, parsed_number} = ExPhoneNumber.parse(phone_number, @origin_country)
            ExPhoneNumber.Formatting.format(parsed_number, :e164)
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.mobile_number, fn
          nil ->
            nil

          phone_number ->
            {:ok, parsed_number} = ExPhoneNumber.parse(phone_number, @origin_country)
            ExPhoneNumber.Formatting.format(parsed_number, :e164)
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.sex, fn
          nil -> nil
          :male -> 1
          :female -> 2
          :other -> 3
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.quar_loc_type, fn
          nil -> 6
          :home -> 1
          :social_medical_facility -> 2
          :hospital -> 3
          :hotel -> 4
          :asylum_center -> 5
          :other -> 7
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_type, fn
          nil -> nil
          :contact_person -> 1
          :travel -> 2
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.test_reason_symptoms, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_work_place, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_army, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_asyl, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_choir, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_club, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_hh, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_high_school, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_childcare, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_erotica, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_flight, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_medical, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_hotel, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_child_home, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_cinema, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_shop, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_school, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_less_300, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_more_300, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_public_transp, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_massage, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_nursing_home, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_religion, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_restaurant, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_school_camp, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_indoor_sport, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_outdoor_sport, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_gathering, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_zoo, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.exp_loc_type_prison, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.other_exp_loc_type, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.test_reason_quarantine, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.test_reason_quarantine_end, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.other_test_reason, fn
          nil -> nil
          true -> 1
          false -> 0
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.test_type, fn
          nil -> 5
          :pcr -> 1
          :serology -> 5
          :quick -> 2
          :antigen_quick -> 3
          :antigen -> 4
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.test_result, fn
          :positive -> 1
          :negative -> 2
          nil -> 3
        end)
        |> List.update_at(@bag_med_16122020_contact_fields_index.vacc_yn, fn
          true -> 1
          false -> 2
          nil -> 3
        end)
      end)

    [@bag_med_16122020_contact_fields]
    |> Stream.concat(cases)
    |> CSV.encode()
  end

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

  @spec get_case_with_lock!(id :: String.t()) :: Case.t()
  def get_case_with_lock!(id),
    do: Repo.one!(from case in Case, where: case.uuid == ^id, lock: "FOR UPDATE")

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
  def create_case(%Person{} = person, attrs),
    do:
      person
      |> create_case_changeset(attrs)
      |> create_case()

  @spec create_case(changeset :: Ecto.Changeset.t(Case.t())) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def create_case(%Ecto.Changeset{data: %Case{}} = changeset),
    do:
      changeset
      |> Case.changeset(%{})
      |> versioning_insert()
      |> broadcast("cases", :create)
      |> versioning_extract()

  @spec create_case(
          person :: Person.t(),
          tenant :: Tenant.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def create_case(%Person{} = person, %Tenant{} = tenant, attrs),
    do:
      person
      |> create_case_changeset(tenant, attrs)
      |> create_case()

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
      |> update_case()

  @spec update_case(changeset :: Ecto.Changeset.t(Case.t())) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def update_case(%Ecto.Changeset{data: %Case{}} = changeset),
    do:
      changeset
      |> Case.changeset(%{})
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
    %Case{person: %Person{contact_methods: contact_methods} = person, tenant: %Tenant{} = tenant} =
      Repo.preload(case, person: [], tenant: [])

    case tenant.outgoing_sms_configuration do
      %Websms{access_token: access_token} ->
        if person_has_mobile_number?(person) do
          phone_number =
            Enum.find_value(contact_methods, fn
              %{type: :mobile, value: value} -> value
              _contact_method -> false
            end)

          {:ok, parsed_number} = ExPhoneNumber.parse(phone_number, @origin_country)
          phone_number = ExPhoneNumber.Formatting.format(parsed_number, :e164)

          message_id = Ecto.UUID.generate()

          case @sms_sender.send(message_id, phone_number, text, access_token) do
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

      nil ->
        {:error, :sms_config_missing}
    end
  end

  @spec case_send_email(case :: Case.t(), subject :: String.t(), body :: String.t()) ::
          {:ok, ProtocolEntry.t()} | {:error, :no_email | :no_outgoing_mail_configuration | term}
  def case_send_email(%Case{} = case, subject, body) do
    %Case{person: %Person{contact_methods: contact_methods} = person, tenant: %Tenant{} = tenant} =
      Repo.preload(case, person: [], tenant: [])

    cond do
      !person_has_email?(person) ->
        {:error, :no_email}

      !TenantContext.tenant_has_outgoing_mail_configuration?(tenant) ->
        {:error, :no_outgoing_mail_configuration}

      true ->
        recipient_email =
          Enum.find_value(contact_methods, fn
            %{type: :email, value: value} -> value
            _contact_method -> false
          end)

        recipient_name =
          [person.first_name, person.last_name]
          |> Enum.reject(&(&1 in ["", nil]))
          |> Enum.join(" ")

        case Smtp.send(recipient_name, recipient_email, subject, body, tenant) do
          :ok ->
            create_protocol_entry(case, %{
              entry: %{__type__: "email", subject: subject, body: body}
            })

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @spec case_phase_automated_email_sent(case :: Case.t(), phase :: Case.Phase.t()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def case_phase_automated_email_sent(%Case{phases: phases} = case, %Case.Phase{uuid: phase_uuid}) do
    case
    |> change_case()
    |> Ecto.Changeset.put_embed(
      :phases,
      Enum.map(phases, fn
        %Case.Phase{uuid: ^phase_uuid} = phase ->
          Case.Phase.changeset(phase, %{automated_close_email_sent: DateTime.utc_now()})

        %Case.Phase{} = phase ->
          Case.Phase.changeset(phase, %{})
      end)
    )
    |> versioning_update()
    |> broadcast("cases", :update)
    |> versioning_extract()
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

  @spec create_case_changeset(
          person :: Person.t(),
          tenant :: Tenant.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Case.t())
  def create_case_changeset(person, tenant, attrs) do
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
  end

  @spec create_case_changeset(
          person :: Person.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Case.t())
  def create_case_changeset(person, attrs) do
    tenant = Repo.preload(person, :tenant).tenant
    create_case_changeset(person, tenant, attrs)
  end

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

  @doc """
  Returns the list of possible_index_submissions.

  ## Examples

      iex> list_possible_index_submissions()
      [%PossibleIndexSubmission{}, ...]

  """
  @spec list_possible_index_submissions :: [PossibleIndexSubmission.t()]
  def list_possible_index_submissions, do: Repo.all(PossibleIndexSubmission)

  @doc """
  Gets a single possible_index_submission.

  Raises `Ecto.NoResultsError` if the Possible index submission does not exist.

  ## Examples

      iex> get_possible_index_submission!(123)
      %PossibleIndexSubmission{}

      iex> get_possible_index_submission!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_possible_index_submission!(id :: String.t()) :: PossibleIndexSubmission.t()
  def get_possible_index_submission!(id), do: Repo.get!(PossibleIndexSubmission, id)

  @doc """
  Creates a possible_index_submission.

  ## Examples

      iex> create_possible_index_submission(%{field: value})
      {:ok, %PossibleIndexSubmission{}}

      iex> create_possible_index_submission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_possible_index_submission(
          case :: Case.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, PossibleIndexSubmission.t()}
          | {:error, Ecto.Changeset.t(PossibleIndexSubmission.t())}
  def create_possible_index_submission(case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:possible_index_submissions)
      |> change_possible_index_submission(attrs)
      |> versioning_insert()
      |> broadcast("possible_index_submissions", :create, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Updates a possible_index_submission.

  ## Examples

      iex> update_possible_index_submission(possible_index_submission, %{field: new_value})
      {:ok, %PossibleIndexSubmission{}}

      iex> update_possible_index_submission(possible_index_submission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_possible_index_submission(
          possible_index_submission :: PossibleIndexSubmission.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, PossibleIndexSubmission.t()}
          | {:error, Ecto.Changeset.t(PossibleIndexSubmission.t())}
  def update_possible_index_submission(
        %PossibleIndexSubmission{} = possible_index_submission,
        attrs
      ),
      do:
        possible_index_submission
        |> change_possible_index_submission(attrs)
        |> versioning_update()
        |> broadcast("possible_index_submissions", :update, & &1.uuid, &["cases:#{&1.case_uuid}"])
        |> versioning_extract()

  @doc """
  Deletes a possible_index_submission.

  ## Examples

      iex> delete_possible_index_submission(possible_index_submission)
      {:ok, %PossibleIndexSubmission{}}

      iex> delete_possible_index_submission(possible_index_submission)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_possible_index_submission(possible_index_submission :: PossibleIndexSubmission.t()) ::
          {:ok, PossibleIndexSubmission.t()}
          | {:error, Ecto.Changeset.t(PossibleIndexSubmission.t())}
  def delete_possible_index_submission(%PossibleIndexSubmission{} = possible_index_submission),
    do:
      possible_index_submission
      |> change_possible_index_submission()
      |> versioning_delete()
      |> broadcast("possible_index_submissions", :delete, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking possible_index_submission changes.

  ## Examples

      iex> change_possible_index_submission(possible_index_submission)
      %Ecto.Changeset{data: %PossibleIndexSubmission{}}

  """
  @spec change_possible_index_submission(
          possible_index_submission ::
            PossibleIndexSubmission.t() | PossibleIndexSubmission.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(PossibleIndexSubmission.t())
  def change_possible_index_submission(
        %PossibleIndexSubmission{} = possible_index_submission,
        attrs \\ %{}
      ) do
    PossibleIndexSubmission.changeset(possible_index_submission, attrs)
  end
end
