defmodule Hygeia.CaseContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Hospitalization
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.EctoType.Country
  alias Hygeia.TenantContext.Tenant

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
              uuid: Ecto.UUID.t(),
              first_name: String.t() | nil,
              last_name: String.t(),
              mobile: String.t() | nil,
              email: String.t() | nil
            }
          ]
        ) :: %{required(uuid :: Ecto.UUID.t()) => [person_id :: Ecto.UUID.t()]}
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

  @spec list_people_by_external_reference(type :: ExternalReference.Type.t(), value: String.t()) ::
          [
            Case.t()
          ]
  def list_people_by_external_reference(type, value),
    do:
      Repo.all(
        from(person in Person,
          where:
            fragment(
              ~S[?::jsonb <@ ANY (?)],
              ^%{type: type, value: value},
              person.external_references
            )
        )
      )

  @spec list_cases_by_external_reference(type :: ExternalReference.Type.t(), value: String.t()) ::
          [
            Case.t()
          ]
  def list_cases_by_external_reference(type, value),
    do:
      Repo.all(
        from(case in Case,
          where:
            fragment(
              ~S[?::jsonb <@ ANY (?)],
              ^%{type: type, value: value},
              case.external_references
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
  @spec get_person!(id :: Ecto.UUID.t()) :: Person.t()
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
      |> change_new_person(attrs)
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
  @spec update_person(
          person :: Person.t() | Ecto.Changeset.t(Person.t()),
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: Person.changeset_options()
        ) ::
          {:ok, Person.t()} | {:error, Ecto.Changeset.t(Person.t())}
  def update_person(person, attrs \\ %{}, changeset_opts \\ %{})

  def update_person(%Person{} = person, attrs, changeset_opts),
    do:
      person
      |> change_person(attrs, changeset_opts)
      |> update_person(%{}, changeset_opts)

  def update_person(%Ecto.Changeset{data: %Person{}} = changeset, attrs, changeset_opts),
    do:
      changeset
      |> change_person(attrs, changeset_opts)
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
          person :: Person.t() | Person.empty() | Changeset.t(Person.t() | Person.empty()),
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: Person.changeset_options()
        ) ::
          Ecto.Changeset.t(Person.t())
  def change_person(person, attrs \\ %{}, opts \\ %{})
  def change_person(%Person{} = person, attrs, opts), do: Person.changeset(person, attrs, opts)

  def change_person(%Changeset{data: %Person{}} = person, attrs, opts),
    do: Person.changeset(person, attrs, opts)

  @spec change_new_person(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Person.t())
  def change_new_person(tenant, attrs \\ %{}) do
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
        fragment("(?->>'quarantine_order')::boolean", phase) and
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
        where:
          fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", person, ^query) or
            fragment("?.fulltext @@ WEBSEARCH_TO_TSQUERY('german', ?)", case, ^query),
        order_by: [
          desc:
            max(
              fragment(
                "TS_RANK_CD((?.fulltext || ?.fulltext), WEBSEARCH_TO_TSQUERY('german', ?))",
                case,
                person,
                ^query
              )
            )
        ],
        group_by: case.uuid,
        limit: ^limit
      )

  def case_export(teant, type, extended \\ false)

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
    :other_exp_loc_type_yn,
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

  @spec case_export(tenant :: Tenant.t(), format :: :bag_med_16122020_case, extended :: boolean) ::
          Enumerable.t()
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def case_export(%Tenant{uuid: tenant_uuid} = _teant, :bag_med_16122020_case, _extended) do
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
        left_join: email in assoc(case, :emails),
        left_join: sms in assoc(case, :sms),
        left_join: employer in assoc(person, :employers),
        left_join: test in assoc(case, :tests),
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
          ^nil,
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
          fragment("(ARRAY_AGG(?))[1]", employer.name),
          # work_place_street
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'address'", employer.address)),
          # work_place_street_number
          ^nil,
          # work_place_location
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'place'", employer.address)),
          # work_place_postal_code
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'zip'", employer.address)),
          # work_place_country
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'country'", employer.address)),
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
          fragment("(?->>'symptom_start')", case.clinical),
          # sampling_dt
          fragment("(ARRAY_AGG(?))[1]", test.tested_at),
          # lab_report_dt
          fragment("(ARRAY_AGG(?))[1]", test.laboratory_reported_at),
          # test_type
          type(fragment("(ARRAY_AGG(?))[1]", test.kind), Test.Kind),
          # test_result
          type(fragment("(ARRAY_AGG(?))[1]", test.result), Test.Result),
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
          fragment("(ARRAY_AGG(?->'known'))[1]", received_transmission.infection_place),
          # activity_mapping_yn
          fragment(
            """
            CASE
              WHEN ? THEN ?
              WHEN ? THEN ?
              WHEN ? THEN ?
              ELSE ?
            END
            """,
            case.status == :canceled,
            false,
            case.status == :first_contact,
            nil,
            case.status == :first_contact_unreachable,
            false,
            true
          ),
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
          # other_exp_loc_type_yn
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "other"
          ),
          # other_exp_loc_type
          fragment("(ARRAY_AGG(?->'type_other'))[1]", received_transmission.infection_place),
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
          ^nil,
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
          fragment("?->>'first_contact'", case.monitoring),
          # quar_yn
          sum(
            fragment(
              "CASE WHEN (?->>'quarantine_order')::boolean THEN 1 ELSE 0 END",
              possible_index_phase
            )
          ) > 0,
          # onset_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", possible_index_phase)),
          # reason_quar
          type(
            fragment(
              "(ARRAY_AGG(?))[1]",
              fragment("?->'details'->>'type'", possible_index_phase)
            ),
            Case.Phase.PossibleIndex.Type
          ),
          # other_reason_quar
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment("?->'details'->>'type_other'", possible_index_phase)
          ),
          # onset_iso_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", index_phase)),
          # iso_loc_type
          type(
            fragment("(?->>'location')", case.monitoring),
            Case.Monitoring.IsolationLocation
          ),
          # other_iso_loc
          fragment("?->>'location_details'", case.monitoring),
          # iso_loc_street
          fragment("?->'address'->>'address'", case.monitoring),
          # iso_loc_street_number
          ^nil,
          # iso_loc_location
          fragment("?->'address'->>'place'", case.monitoring),
          # iso_loc_postal_code
          fragment("?->'address'->>'zip'", case.monitoring),
          # iso_loc_country
          fragment("?->'address'->>'country'", case.monitoring),
          # follow_up_dt
          fragment(
            "GREATEST(?, ?)",
            fragment("(?)::date", max(sms.inserted_at)),
            fragment("(?)::date", max(email.inserted_at))
          ),
          # end_of_iso_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'end'", index_phase)),
          # reason_end_of_iso
          fragment("(ARRAY_AGG(?))[1]", fragment("?->'detail'->>'end_reason'", index_phase)),
          # other_reason_end_of_iso
          fragment(
            "(ARRAY_AGG(?))[1]",
            fragment("?->'detail'->>'other_end_reason'", index_phase)
          ),
          # vacc_yn
          fragment("(?->>'done')::boolean", person.vaccination),
          # vacc_name
          fragment("?->>'name'", person.vaccination),
          # vacc_dose
          fragment(
            "CASE WHEN ? THEN ? ELSE ? END",
            is_nil(fragment("?->>'jab_dates'", person.vaccination)),
            nil,
            fragment("JSONB_ARRAY_LENGTH(?)", fragment("?->'jab_dates'", person.vaccination))
          ),
          # vacc_dt_first
          fragment("(?->'jab_dates'->>0)", person.vaccination),
          # vacc_dt_last
          fragment("(?->'jab_dates'->>-1)", person.vaccination)
        ]
      )
      |> Repo.stream()
      |> Stream.map(fn entry ->
        entry
        |> normalize_ism_id(@bag_med_16122020_case_fields_index.fall_id_ism)
        |> normalize_ism_id(@bag_med_16122020_case_fields_index.case_link_fall_id_ism)
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
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_symptoms)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_outbreak)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_cohort)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_work_screening)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_quarantine)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_app)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.test_reason_convenience)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_work_place)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_army)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_asyl)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_choir)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_club)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_hh)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_high_school)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_childcare)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_erotica)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_flight)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_medical)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_hotel)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_child_home)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_cinema)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_shop)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_school)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_less_300)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_more_300)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_public_transp)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_massage)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_nursing_home)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_religion)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_restaurant)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_school_camp)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_indoor_sport)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_outdoor_sport)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_gathering)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_zoo)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_prison)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.other_exp_loc_type_yn)
        |> normalize_boolean_and_unknown_field(
          @bag_med_16122020_case_fields_index.activity_mapping_yn
        )
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.symptoms_yn)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.case_link_yn)
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
          :inconclusive -> 3
          nil -> 3
        end)
        |> List.update_at(@bag_med_16122020_case_fields_index.reason_end_of_iso, fn
          # :other -> 4
          nil -> nil
          :healed -> 1
          :death -> 2
          :no_follow_up -> 3
        end)
        |> normalize_boolean_and_unknown_field(@bag_med_16122020_case_fields_index.vacc_yn)
        |> normalize_boolean_field(@bag_med_16122020_case_fields_index.exp_loc_type_yn)
        |> normalize_boolean_and_unknown_field(@bag_med_16122020_case_fields_index.quar_yn)
        |> normalize_country(@bag_med_16122020_case_fields_index.country)
        |> normalize_country(@bag_med_16122020_case_fields_index.work_place_country)
        |> normalize_country(@bag_med_16122020_case_fields_index.exp_country)
        |> normalize_country(@bag_med_16122020_case_fields_index.iso_loc_country)
        |> List.update_at(@bag_med_16122020_case_fields_index.reason_quar, fn
          nil -> nil
          :contact_person -> 1
          :travel -> 2
          :outbreak -> 3
          :covid_app -> 4
          :other -> 5
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
    :hygeia_case_link_region_subdivision,
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
    :other_exp_loc_type_yn,
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

  @extended_fields [:hygeia_case_link_region_subdivision]
                   |> Enum.map(fn field ->
                     Enum.find_index(@bag_med_16122020_contact_fields, &(field == &1))
                   end)
                   |> Enum.sort(:desc)

  @bag_med_16122020_contact_fields_index @bag_med_16122020_contact_fields
                                         |> Enum.with_index()
                                         |> Map.new()

  @spec case_export(
          tenant :: Tenant.t(),
          format :: :bag_med_16122020_contact,
          extended :: boolean
        ) :: Enumerable.t()
  # credo:disable-for-lines:2 Credo.Check.Refactor.ABCSize
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def case_export(%Tenant{uuid: tenant_uuid} = _teant, :bag_med_16122020_contact, extended) do
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
          received_transmission_case_tenant in assoc(received_transmission_case, :tenant),
        left_join:
          received_transmission_case_ism_id in fragment(
            "UNNEST(?)",
            received_transmission_case.external_references
          ),
        on: fragment("?->>'type'", received_transmission_case_ism_id) == "ism_case",
        left_join: employer in assoc(person, :employers),
        left_join: test in assoc(case, :tests),
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
          ^nil,
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
          fragment("(ARRAY_AGG(?))[1]", employer.name),
          # work_place_postal_code
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'zip'", employer.address)),
          # work_place_country
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'country'", employer.address)),
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
          # hygeia_case_link_region_subdivision
          fragment(
            "(ARRAY_AGG(?))[1]",
            received_transmission_case_tenant.subdivision
          ),
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
          # other_exp_loc_type_yn
          fragment(
            "(ARRAY_AGG(?->'type' \\? ?))[1]",
            received_transmission.infection_place,
            "other"
          ),
          # other_exp_loc_type
          fragment("(ARRAY_AGG(?->'type_other'))[1]", received_transmission.infection_place),
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
          ^nil,
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
          fragment("?->'reasons_for_test' \\? ?", case.clinical, "quarantine_end"),
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
          fragment("(?->>'symptom_start')", case.clinical),
          # test_type
          type(fragment("(ARRAY_AGG(?))[1]", test.kind), Test.Kind),
          # sampling_dt
          fragment("(ARRAY_AGG(?))[1]", test.tested_at),
          # test_result
          type(fragment("(ARRAY_AGG(?))[1]", test.result), Test.Result),
          # onset_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'start'", phase)),
          # end_quar_dt
          fragment("(ARRAY_AGG(?))[1]", fragment("?->>'end'", phase)),
          # reason_end_quar
          type(
            fragment("(ARRAY_AGG(?))[1]", fragment("?->'details'->>'end_reason'", phase)),
            Case.Phase.PossibleIndex.EndReason
          ),
          # other_reason_end_quar
          fragment("(ARRAY_AGG(?))[1]", fragment("?->'details'->>'other_end_reason'", phase)),
          # vacc_yn
          fragment("(?->>'done')::boolean", person.vaccination),
          # vacc_name
          fragment("?->>'name'", person.vaccination),
          # vacc_dose
          fragment(
            "CASE WHEN ? THEN ? ELSE ? END",
            is_nil(fragment("?->>'jab_dates'", person.vaccination)),
            nil,
            fragment("JSONB_ARRAY_LENGTH(?)", fragment("?->'jab_dates'", person.vaccination))
          ),
          # vacc_dt_first
          fragment("(?->'jab_dates'->>0)", person.vaccination),
          # vacc_dt_last
          fragment("(?->'jab_dates'->>-1)", person.vaccination)
        ]
      )
      |> Repo.stream()
      |> Stream.map(fn entry ->
        entry
        |> normalize_ism_id(@bag_med_16122020_contact_fields_index.case_link_fall_id_ism)
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
          :other -> nil
          :contact_person -> 1
          :travel -> 2
          :outbreak -> 2
          :covid_app -> 1
        end)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.test_reason_symptoms)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_work_place)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_army)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_asyl)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_choir)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_club)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_hh)
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_high_school
        )
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_childcare)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_erotica)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_flight)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_medical)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_hotel)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_child_home)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_cinema)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_shop)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_school)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_less_300)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_more_300)
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_public_transp
        )
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_massage)
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_nursing_home
        )
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_religion)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_restaurant)
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_school_camp
        )
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_indoor_sport
        )
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.exp_loc_type_outdoor_sport
        )
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_gathering)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_zoo)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.exp_loc_type_prison)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.other_exp_loc_type_yn)
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.test_reason_quarantine)
        |> normalize_boolean_field(
          @bag_med_16122020_contact_fields_index.test_reason_quarantine_end
        )
        |> normalize_boolean_field(@bag_med_16122020_contact_fields_index.other_test_reason)
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
          :inconclusive -> 3
          nil -> 3
        end)
        |> normalize_boolean_and_unknown_field(@bag_med_16122020_contact_fields_index.vacc_yn)
        |> normalize_country(@bag_med_16122020_contact_fields_index.country)
        |> normalize_country(@bag_med_16122020_contact_fields_index.work_place_country)
        |> normalize_country(@bag_med_16122020_contact_fields_index.exp_country)
        |> (fn list ->
              case Enum.at(list, @bag_med_16122020_contact_fields_index.reason_end_quar) do
                :negative_test ->
                  list
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    4
                  )
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.other_reason_end_quar)],
                    "Negative Test"
                  )

                :immune ->
                  list
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    4
                  )
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.other_reason_end_quar)],
                    "Immune"
                  )

                :vaccinated ->
                  list
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    4
                  )
                  |> put_in(
                    [Access.at!(@bag_med_16122020_contact_fields_index.other_reason_end_quar)],
                    "Vaccinated"
                  )

                :asymptomatic ->
                  put_in(
                    list,
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    1
                  )

                :converted_to_index ->
                  put_in(
                    list,
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    2
                  )

                :no_follow_up ->
                  put_in(
                    list,
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    3
                  )

                :other ->
                  put_in(
                    list,
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    4
                  )

                nil ->
                  put_in(
                    list,
                    [Access.at!(@bag_med_16122020_contact_fields_index.reason_end_quar)],
                    nil
                  )
              end
            end).()
      end)

    export = Stream.concat([@bag_med_16122020_contact_fields], cases)

    export =
      if extended do
        export
      else
        Stream.map(export, fn entry ->
          Enum.reduce(@extended_fields, entry, &List.delete_at(&2, &1))
        end)
      end

    CSV.encode(export)
  end

  defp normalize_boolean_field(row, field_number) do
    List.update_at(row, field_number, fn
      nil -> nil
      true -> 1
      false -> 0
    end)
  end

  defp normalize_boolean_and_unknown_field(row, field_number) do
    List.update_at(row, field_number, fn
      nil -> 3
      true -> 1
      false -> 2
    end)
  end

  defp normalize_country(row, field_number) do
    List.update_at(row, field_number, fn
      nil -> nil
      country -> Country.bfs_code(country)
    end)
  end

  defp normalize_ism_id(row, field_number) do
    List.update_at(row, field_number, fn
      nil ->
        nil

      id ->
        case Integer.parse(id) do
          {id, ""} -> id
          {_id, _rest} -> nil
          :error -> nil
        end
    end)
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
  @spec get_case!(id :: Ecto.UUID.t()) :: Case.t()
  def get_case!(id), do: Repo.get!(Case, id)

  @spec get_case_with_lock!(id :: Ecto.UUID.t()) :: Case.t()
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
      |> change_new_case(attrs)
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
      |> change_new_case(tenant, attrs)
      |> create_case()

  @doc """
  Updates a case.

  ## Examples

      iex> update_case(case, %{field: new_value})
      {:ok, %Case{}}

      iex> update_case(case, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_case(
          case :: Case.t() | Ecto.Changeset.t(Case.t()),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: Case.changeset_params()
        ) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def update_case(case, attrs \\ %{}, changeset_params \\ %{})

  def update_case(%Case{} = case, attrs, changeset_params),
    do:
      case
      |> change_case(attrs, changeset_params)
      |> update_case()

  @spec update_case(changeset :: Ecto.Changeset.t(Case.t())) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def update_case(%Ecto.Changeset{data: %Case{}} = changeset, attrs, changeset_params),
    do:
      changeset
      |> change_case(attrs, changeset_params)
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
  def delete_case(%Case{} = case),
    do:
      case
      |> change_case()
      |> versioning_delete()
      |> broadcast("cases", :delete)
      |> versioning_extract()

  @spec case_phase_automated_email_sent(case :: Case.t(), phase :: Case.Phase.t()) ::
          {:ok, Case.t()} | {:error, Ecto.Changeset.t(Case.t())}
  def case_phase_automated_email_sent(%Case{phases: phases} = case, %Case.Phase{uuid: phase_uuid}) do
    case
    |> Ecto.Changeset.change()
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
          case :: Case.t() | Case.empty() | Changeset.t(Case.t() | Case.empty()),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: Case.changeset_params()
        ) ::
          Ecto.Changeset.t(Case.t())
  def change_case(case, attrs \\ %{}, changeset_params \\ %{})

  def change_case(%Case{} = case, attrs, changeset_params),
    do: Case.changeset(case, attrs, changeset_params)

  def change_case(%Changeset{data: %Case{}} = case, attrs, changeset_params),
    do: Case.changeset(case, attrs, changeset_params)

  @spec change_new_case(
          person :: Person.t(),
          tenant :: Tenant.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Case.t())
  def change_new_case(person, tenant, attrs) do
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

  @spec change_new_case(
          person :: Person.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Case.t())
  def change_new_case(person, attrs) do
    tenant = Repo.preload(person, :tenant).tenant
    change_new_case(person, tenant, attrs)
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
  @spec get_transmission!(id :: Ecto.UUID.t()) :: Transmission.t()
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

  @spec create_transmission(
          transmission :: Transmission.t() | Ecto.Changeset.t(Transmission.t()),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Transmission.t()} | {:error, Ecto.Changeset.t(Transmission.t())}
  def create_transmission(transmission, attrs),
    do:
      transmission
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
          transmission :: Transmission.t() | Ecto.Changeset.t(Transmission.t()),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: Transmission.changeset_params()
        ) :: {:ok, Transmission.t()} | {:error, Ecto.Changeset.t(Transmission.t())}
  def update_transmission(transmission, attrs \\ %{}, changeset_params \\ %{})

  def update_transmission(%Transmission{} = transmission, attrs, changeset_params),
    do:
      transmission
      |> change_transmission(attrs, changeset_params)
      |> update_transmission()

  def update_transmission(
        %Ecto.Changeset{data: %Transmission{}} = changeset,
        attrs,
        changeset_params
      ),
      do:
        changeset
        |> change_transmission(attrs, changeset_params)
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
          transmission ::
            Transmission.t()
            | Transmission.empty()
            | Changeset.t(Transmission.t() | Transmission.empty()),
          attrs :: Hygeia.ecto_changeset_params(),
          changeset_params :: Transmission.changeset_params()
        ) ::
          Ecto.Changeset.t(Transmission.t())
  def change_transmission(transmission, attrs \\ %{}, changeset_params \\ %{})

  def change_transmission(%Transmission{} = transmission, attrs, changeset_params),
    do: Transmission.changeset(transmission, attrs, changeset_params)

  def change_transmission(
        %Ecto.Changeset{data: %Transmission{}} = transmission,
        attrs,
        changeset_params
      ),
      do: Transmission.changeset(transmission, attrs, changeset_params)

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes()
      [%Note{}, ...]

  """
  @spec list_notes :: [Note.t()]
  def list_notes, do: Repo.all(Note)

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Protocol entry does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_note!(id :: Ecto.UUID.t()) :: Note.t()
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_note(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t(Note.t())}
  def create_note(%Case{} = case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:notes)
      |> change_note(attrs)
      |> versioning_insert()
      |> broadcast(
        "notes",
        :create,
        & &1.uuid,
        &["notes:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_note(
          note :: Note.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t(Note.t())}
  def update_note(%Note{} = note, attrs),
    do:
      note
      |> change_note(attrs)
      |> versioning_update()
      |> broadcast(
        "notes",
        :update,
        & &1.uuid,
        &["notes:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_note(note :: Note.t()) ::
          {:ok, Note.t()} | {:error, Ecto.Changeset.t(Note.t())}
  def delete_note(%Note{} = note),
    do:
      note
      |> change_note()
      |> versioning_delete()
      |> broadcast(
        "notes",
        :delete,
        & &1.uuid,
        &["notes:case:#{&1.case_uuid}"]
      )
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  @spec change_note(
          note :: Note.t() | Note.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Note.t())
  def change_note(%Note{} = note, attrs \\ %{}),
    do: Note.changeset(note, attrs)

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
  @spec get_possible_index_submission!(id :: Ecto.UUID.t()) :: PossibleIndexSubmission.t()
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

  @doc """
  Returns the list of hospitalizations.

  ## Examples

      iex> list_hospitalizations()
      [%Hospitalization{}, ...]

  """
  @spec list_hospitalizations :: [Hospitalization.t()]
  def list_hospitalizations, do: Repo.all(Hospitalization)

  @doc """
  Gets a single hospitalization.

  Raises `Ecto.NoResultsError` if the Possible index submission does not exist.

  ## Examples

      iex> get_hospitalization!(123)
      %Hospitalization{}

      iex> get_hospitalization!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_hospitalization!(id :: Ecto.UUID.t()) :: Hospitalization.t()
  def get_hospitalization!(id), do: Repo.get!(Hospitalization, id)

  @doc """
  Creates a hospitalization.

  ## Examples

      iex> create_hospitalization(%{field: value})
      {:ok, %Hospitalization{}}

      iex> create_hospitalization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_hospitalization(
          case :: Case.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Hospitalization.t()}
          | {:error, Ecto.Changeset.t(Hospitalization.t())}
  def create_hospitalization(case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:hospitalizations)
      |> change_hospitalization(attrs)
      |> versioning_insert()
      |> broadcast("hospitalizations", :create, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Updates a hospitalization.

  ## Examples

      iex> update_hospitalization(hospitalization, %{field: new_value})
      {:ok, %Hospitalization{}}

      iex> update_hospitalization(hospitalization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_hospitalization(
          hospitalization :: Hospitalization.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Hospitalization.t()}
          | {:error, Ecto.Changeset.t(Hospitalization.t())}
  def update_hospitalization(
        %Hospitalization{} = hospitalization,
        attrs
      ),
      do:
        hospitalization
        |> change_hospitalization(attrs)
        |> versioning_update()
        |> broadcast("hospitalizations", :update, & &1.uuid, &["cases:#{&1.case_uuid}"])
        |> versioning_extract()

  @doc """
  Deletes a hospitalization.

  ## Examples

      iex> delete_hospitalization(hospitalization)
      {:ok, %Hospitalization{}}

      iex> delete_hospitalization(hospitalization)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_hospitalization(hospitalization :: Hospitalization.t()) ::
          {:ok, Hospitalization.t()}
          | {:error, Ecto.Changeset.t(Hospitalization.t())}
  def delete_hospitalization(%Hospitalization{} = hospitalization),
    do:
      hospitalization
      |> change_hospitalization()
      |> versioning_delete()
      |> broadcast("hospitalizations", :delete, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hospitalization changes.

  ## Examples

      iex> change_hospitalization(hospitalization)
      %Ecto.Changeset{data: %Hospitalization{}}

  """
  @spec change_hospitalization(
          hospitalization ::
            Hospitalization.t() | Hospitalization.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Hospitalization.t())
  def change_hospitalization(
        %Hospitalization{} = hospitalization,
        attrs \\ %{}
      ) do
    Hospitalization.changeset(hospitalization, attrs)
  end

  @spec list_protocol_entries(case :: Case.t(), limit :: pos_integer()) :: [
          %{
            version: Hygeia.VersionContext.Version.t(),
            entry: Note.t() | Email.t() | SMS.t(),
            inserted_at: DateTime.t()
          }
        ]
  def list_protocol_entries(case, limit \\ 100) do
    note_query =
      from(note in Ecto.assoc(case, :notes),
        select: {note.inserted_at, "note", note.uuid},
        limit: ^limit
      )

    note_sms_query =
      from(sms in Ecto.assoc(case, :sms),
        select: {sms.inserted_at, "sms", sms.uuid},
        union_all: ^note_query
      )

    note_sms_email_query =
      from(email in Ecto.assoc(case, :emails),
        select: {email.inserted_at, "email", email.uuid},
        order_by: fragment("inserted_at"),
        union_all: ^note_sms_query
      )

    protocol_entries = Repo.all(note_sms_email_query)

    resources =
      protocol_entries
      |> Enum.group_by(&elem(&1, 1), &elem(&1, 2))
      |> Enum.flat_map(&load_protocol_entries(case, &1))
      |> Map.new()

    Enum.map(protocol_entries, fn {inserted_at, _type, uuid} ->
      {resource, version} = Map.fetch!(resources, uuid)
      {uuid, inserted_at, resource, version}
    end)
  end

  defp load_protocol_entries(case, {"sms", ids}),
    do:
      Repo.all(
        from(version in Hygeia.VersionContext.Version,
          join: sms in ^Ecto.assoc(case, :sms),
          on:
            fragment("(?->>'uuid')::uuid", version.item_pk) == sms.uuid and
              version.item_table == "sms" and
              version.event == :insert,
          select: {sms.uuid, {sms, version}},
          where: fragment("?->>'uuid'", version.item_pk) in ^ids,
          preload: [:user]
        )
      )

  defp load_protocol_entries(case, {"email", ids}),
    do:
      Repo.all(
        from(version in Hygeia.VersionContext.Version,
          join: email in ^Ecto.assoc(case, :emails),
          on:
            fragment("(?->>'uuid')::uuid", version.item_pk) == email.uuid and
              version.item_table == "emails" and
              version.event == :insert,
          select: {email.uuid, {email, version}},
          where: fragment("?->>'uuid'", version.item_pk) in ^ids,
          preload: [:user]
        )
      )

  defp load_protocol_entries(case, {"note", ids}),
    do:
      Repo.all(
        from(version in Hygeia.VersionContext.Version,
          join: note in ^Ecto.assoc(case, :notes),
          on:
            fragment("(?->>'uuid')::uuid", version.item_pk) == note.uuid and
              version.item_table == "notes" and
              version.event == :insert,
          select: {note.uuid, {note, version}},
          where: fragment("?->>'uuid'", version.item_pk) in ^ids,
          preload: [:user]
        )
      )

  @doc """
  Returns the list of tests.

  ## Examples

      iex> list_tests()
      [%Test{}, ...]

  """
  @spec list_tests :: [Test.t()]
  def list_tests, do: Repo.all(Test)

  @doc """
  Gets a single test.

  Raises `Ecto.NoResultsError` if the Test does not exist.

  ## Examples

      iex> get_test!(123)
      %Test{}

      iex> get_test!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_test!(id :: Ecto.UUID.t()) :: Test.t()
  def get_test!(id), do: Repo.get!(Test, id)

  @doc """
  Creates a test.

  ## Examples

      iex> create_test(%{field: value})
      {:ok, %Test{}}

      iex> create_test(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_test(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Test.t()} | {:error, Ecto.Changeset.t(Test.t())}
  def create_test(case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:tests)
      |> change_test(attrs)
      |> versioning_insert()
      |> broadcast("tests", :create, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Updates a test.

  ## Examples

      iex> update_test(test, %{field: new_value})
      {:ok, %Test{}}

      iex> update_test(test, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_test(test :: Test.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Test.t()} | {:error, Ecto.Changeset.t(Test.t())}
  def update_test(%Test{} = test, attrs),
    do:
      test
      |> change_test(attrs)
      |> versioning_update()
      |> broadcast("tests", :update, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Deletes a test.

  ## Examples

      iex> delete_test(test)
      {:ok, %Test{}}

      iex> delete_test(test)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_test(test :: Test.t()) :: {:ok, Test.t()} | {:error, Ecto.Changeset.t(Test.t())}
  def delete_test(%Test{} = test),
    do:
      test
      |> change_test()
      |> versioning_delete()
      |> broadcast("tests", :delete, & &1.uuid, &["cases:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking test changes.

  ## Examples

      iex> change_test(test)
      %Ecto.Changeset{data: %Test{}}

  """
  @spec change_test(test :: Test.t() | Test.empty(), attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t(Test.t())
  def change_test(%Test{} = test, attrs \\ %{}), do: Test.changeset(test, attrs)

  @doc """
  Returns the list of premature_releases.

  ## Examples

      iex> list_premature_releases()
      [%PrematureRelease{}, ...]

  """
  @spec list_premature_releases :: [PrematureRelease.t()]
  def list_premature_releases, do: Repo.all(PrematureRelease)

  @spec list_premature_releases(case :: Case.t()) :: [PrematureRelease.t()]
  def list_premature_releases(%Case{} = case),
    do: case |> Ecto.assoc(:premature_releases) |> Repo.all()

  @doc """
  Gets a single premature_release.

  Raises `Ecto.NoResultsError` if the Premature release does not exist.

  ## Examples

      iex> get_premature_release!(123)
      %PrematureRelease{}

      iex> get_premature_release!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_premature_release!(id :: Ecto.UUID.t()) :: PrematureRelease.t()
  def get_premature_release!(id), do: Repo.get!(PrematureRelease, id)

  @doc """
  Creates a premature_release.

  ## Examples

      iex> create_premature_release(%{field: value})
      {:ok, %PrematureRelease{}}

      iex> create_premature_release(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_premature_release(
          case :: Case.t(),
          phase :: Case.Phase.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, PrematureRelease.t()} | {:error, Ecto.Changeset.t(PrematureRelease.t())}
  def create_premature_release(%Case{} = case, %Case.Phase{} = phase, attrs \\ %{}),
    do:
      case
      |> change_new_premature_release(phase, attrs)
      |> versioning_insert()
      |> broadcast("premature_releases", :create)
      |> versioning_extract()

  @doc """
  Updates a premature_release.

  ## Examples

      iex> update_premature_release(premature_release, %{field: new_value})
      {:ok, %PrematureRelease{}}

      iex> update_premature_release(premature_release, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_premature_release(
          premature_release :: PrematureRelease.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, PrematureRelease.t()} | {:error, Ecto.Changeset.t(PrematureRelease.t())}

  def update_premature_release(%PrematureRelease{} = premature_release, attrs),
    do:
      premature_release
      |> change_premature_release(attrs)
      |> versioning_update()
      |> broadcast("premature_releases", :update)
      |> versioning_extract()

  @doc """
  Deletes a premature_release.

  ## Examples

      iex> delete_premature_release(premature_release)
      {:ok, %PrematureRelease{}}

      iex> delete_premature_release(premature_release)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_premature_release(premature_release :: PrematureRelease.t()) ::
          {:ok, PrematureRelease.t()} | {:error, Ecto.Changeset.t(PrematureRelease.t())}

  def delete_premature_release(%PrematureRelease{} = premature_release),
    do:
      premature_release
      |> change_premature_release()
      |> versioning_delete()
      |> broadcast("premature_releases", :delete)
      |> versioning_extract()

  @spec change_new_premature_release(
          case :: Case.t(),
          phase :: Case.Phase.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(PrematureRelease.t())
  def change_new_premature_release(%Case{} = case, %Case.Phase{} = phase, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:premature_releases)
      |> Changeset.change(%{phase_uuid: phase.uuid})
      |> PrematureRelease.create_changeset(attrs)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking premature_release changes.

  ## Examples

      iex> change_premature_release(premature_release)
      %Ecto.Changeset{data: %PrematureRelease{}}

  """
  @spec change_premature_release(
          premature_release :: PrematureRelease.t() | PrematureRelease.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(PrematureRelease.t())
  def change_premature_release(%PrematureRelease{} = premature_release, attrs \\ %{}),
    do: PrematureRelease.changeset(premature_release, attrs)
end
