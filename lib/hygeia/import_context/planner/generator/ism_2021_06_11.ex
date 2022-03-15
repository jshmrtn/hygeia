# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11 do
  @moduledoc false

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.Test
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Row
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant

  @type field_mapping :: %{required(atom) => String.t()}

  @origin_country Application.compile_env!(:hygeia, [:phone_number_parsing_origin_country])

  @external_reference_mapping [
    {:case, :ism_case, :case_id},
    {:case, :ism_report, :report_id},
    {:person, :ism_patient, :patient_id}
  ]

  @person_field_path %{
    last_name: [:last_name],
    first_name: [:first_name],
    birth_date: [:birth_date],
    sex: [:sex],
    phone: [:phone],
    email: [:email],
    address: [:address, :address],
    zip: [:address, :zip],
    place: [:address, :place],
    subdivision: [:address, :subdivision],
    country: [:address, :country]
  }

  @test_field_path %{
    tested_at: [:tested_at],
    laboratory_reported_at: [:laboratory_reported_at],
    test_result: [:result],
    test_kind: [:kind],
    test_reference: [:reference],
    reporting_unit_name: [:reporting_unit, :name],
    reporting_unit_division: [:reporting_unit, :division],
    reporting_unit_person_first_name: [:reporting_unit, :person_first_name],
    reporting_unit_person_last_name: [:reporting_unit, :person_last_name],
    reporting_unit_address: [:reporting_unit, :address, :address],
    reporting_unit_zip: [:reporting_unit, :address, :zip],
    reporting_unit_place: [:reporting_unit, :address, :place],
    sponsor_name: [:sponsor, :name],
    sponsor_division: [:sponsor, :division],
    sponsor_person_first_name: [:sponsor, :person_first_name],
    sponsor_person_last_name: [:sponsor, :person_last_name],
    sponsor_address: [:sponsor, :address, :address],
    sponsor_zip: [:sponsor, :address, :zip],
    sponsor_place: [:sponsor, :address, :place],
    mutation_ism_code: [:mutation, :ism_code]
  }

  @spec select_tenant(field_mapping :: field_mapping) ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def select_tenant(field_mapping) do
    fn %Row{tenant: row_tenant}, %{data: data, tenants: tenants} = _params, _preceeding_steps ->
      {certainty, tenant} =
        with subdivision when is_binary(subdivision) <-
               Row.get_change_field(data, [field_mapping.tenant_subdivision]),
             %Tenant{} = tenant <-
               Enum.find(tenants, &match?(%Tenant{subdivision: ^subdivision}, &1)) do
          certainty =
            cond do
              !Tenant.is_internal_managed_tenant?(tenant) -> :input_needed
              tenant.uuid != row_tenant.uuid -> :uncertain
              true -> :certain
            end

          {certainty, tenant}
        else
          nil -> {:uncertain, row_tenant}
        end

      {certainty, %Planner.Action.ChooseTenant{tenant: tenant}}
    end
  end

  @spec select_case(field_mapping :: field_mapping, relevance_date_field :: String.t()) ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def select_case(field_mapping, relevance_date_field) do
    fn _row, %{predecessor: predecessor, data: data}, _preceeding_steps ->
      with date when date != nil <- Row.get_change_field(data, [relevance_date_field]),
           {:ok, date} <- Date.from_iso8601(date) do
        select_case_with_relevance_date(field_mapping, date, data, predecessor)
      else
        _no_date_or_error ->
          select_case_with_relevance_date(
            field_mapping,
            Date.utc_today(),
            data,
            predecessor,
            :input_needed
          )
      end
    end
  end

  defp select_case_with_relevance_date(
         field_mapping,
         relevance_date,
         data,
         predecessor,
         max_certainty \\ :certain
       )

  defp select_case_with_relevance_date(
         _field_mapping,
         relevance_date,
         _data,
         %Row{case: %Case{} = case},
         max_certainty
       ) do
    {certainty, action} =
      case
      |> preload_case()
      |> select_case_certainty(relevance_date)

    {Planner.limit_certainty(max_certainty, certainty), action}
  end

  defp select_case_with_relevance_date(
         field_mapping,
         relevance_date,
         data,
         _row_with_no_case_or_nil,
         max_certainty
       ) do
    {certainty, action} =
      Enum.reduce_while(
        [
          fn ->
            find_case_by_external_reference(
              :ism_case,
              Row.get_change_field(data, [field_mapping.case_id]),
              relevance_date
            )
          end,
          fn ->
            find_case_by_external_reference(
              :ism_report,
              Row.get_change_field(data, [field_mapping.report_id]),
              relevance_date
            )
          end,
          fn ->
            find_person_by_external_reference(
              :ism_patient,
              Row.get_change_field(data, [field_mapping.patient_id]),
              relevance_date
            )
          end,
          fn ->
            find_person_by_name(
              Row.get_change_field(data, [field_mapping.first_name]),
              Row.get_change_field(data, [field_mapping.last_name]),
              data,
              field_mapping,
              relevance_date
            )
          end,
          fn ->
            find_person_by_phone(
              Row.get_change_field(data, [field_mapping.phone]),
              relevance_date
            )
          end,
          fn ->
            find_person_by_email(
              Row.get_change_field(data, [field_mapping[:email]]),
              relevance_date
            )
          end
        ],
        {:certain, %Planner.Action.SelectCase{}},
        fn search_fn, acc ->
          case search_fn.() do
            {:ok, {certainty, action}} -> {:halt, {certainty, action}}
            :error -> {:cont, acc}
          end
        end
      )

    {Planner.limit_certainty(max_certainty, certainty), action}
  end

  defp find_case_by_external_reference(type, id, relevance_date)
  defp find_case_by_external_reference(_type, "", _relevance_date), do: :error
  defp find_case_by_external_reference(_type, nil, _relevance_date), do: :error

  defp find_case_by_external_reference(type, id, relevance_date) do
    case CaseContext.list_cases_by_external_reference(type, to_string(id)) do
      [] ->
        :error

      [case] ->
        {:ok,
         case
         |> preload_case
         |> select_case_certainty(relevance_date)}

      [case | _] ->
        {certainty, action} =
          case
          |> preload_case
          |> select_case_certainty(relevance_date)

        {:ok, {Planner.limit_certainty(:input_needed, certainty), action}}
    end
  end

  defp select_case_certainty(case, relevance_date) do
    index_phase_date =
      case
      |> Case.phase_dates(Phase.Index)
      |> Enum.map(fn {_key, value} -> value end)
      |> Enum.max(Date)

    possible_index_phase_date =
      case
      |> Case.phase_dates(Phase.PossibleIndex)
      |> Enum.map(fn {_key, value} -> value end)
      |> Enum.max(Date)

    case.phases
    |> Enum.find(&match?(%Case.Phase{details: %Phase.Index{}}, &1))
    |> case do
      nil ->
        select_case_certainty_possible_index(case, possible_index_phase_date, relevance_date)

      index_phase ->
        select_case_certainty_index(case, index_phase, index_phase_date, relevance_date)
    end
  end

  defp select_case_certainty_index(case, index_phase, index_phase_date, relevance_date) do
    date_diff = abs(Date.diff(index_phase_date, relevance_date))

    cond do
      date_diff <= 10 and index_phase.end != nil and index_phase.start != nil and
          relevance_date in Date.range(index_phase.start, index_phase.end) ->
        {:certain, %Planner.Action.SelectCase{case: case, person: case.person}}

      date_diff <= 10 ->
        {:uncertain, %Planner.Action.SelectCase{case: case, person: case.person}}

      date_diff <= 30 ->
        {:input_needed,
         %Planner.Action.SelectCase{
           case: case,
           person: case.person,
           suppress_quarantine: true
         }}

      date_diff > 30 ->
        {:input_needed,
         %Planner.Action.SelectCase{
           case: case,
           person: case.person,
           suppress_quarantine: false
         }}
    end
  end

  defp select_case_certainty_possible_index(case, possible_index_phase_date, relevance_date) do
    date_diff = abs(Date.diff(possible_index_phase_date, relevance_date))

    cond do
      date_diff <= 10 ->
        {:certain, %Planner.Action.SelectCase{case: case, person: case.person}}

      date_diff > 10 ->
        {:input_needed, %Planner.Action.SelectCase{case: case, person: case.person}}
    end
  end

  defp find_person_by_external_reference(type, id, relevance_date)
  defp find_person_by_external_reference(_type, "", _relevance_date), do: :error
  defp find_person_by_external_reference(_type, nil, _relevance_date), do: :error

  defp find_person_by_external_reference(type, id, relevance_date) do
    case CaseContext.list_people_by_external_reference(type, to_string(id)) do
      [] ->
        :error

      [person] ->
        {:ok, select_active_cases(preload_person(person), relevance_date, :certain)}

      [person | _] ->
        {:ok, select_active_cases(preload_person(person), relevance_date, :input_needed)}
    end
  end

  defp find_person_by_name(first_name, last_name, changes, field_mapping, relevance_date)
  defp find_person_by_name(nil, _last_name, _changes, _field_mapping, _relevance_date), do: :error
  defp find_person_by_name("", _last_name, _changes, _field_mapping, _relevance_date), do: :error

  defp find_person_by_name(_first_name, nil, _changes, _field_mapping, _relevance_date),
    do: :error

  defp find_person_by_name(_first_name, "", _changes, _field_mapping, _relevance_date), do: :error

  defp find_person_by_name(first_name, last_name, changes, field_mapping, relevance_date) do
    first_name
    |> CaseContext.list_people_by_name(last_name)
    |> preload_person()
    |> Enum.reduce({[], []}, fn person, {acc_phone_match, acc_phone_no_match} ->
      if person_phone_matches?(person, Row.get_change_field(changes, [field_mapping.phone])) do
        {acc_phone_match ++ [person], acc_phone_no_match}
      else
        {acc_phone_match, acc_phone_no_match ++ [person]}
      end
    end)
    |> case do
      {[], []} ->
        :error

      {[person], []} ->
        {:ok, select_active_cases(person, relevance_date)}

      {[], [person]} ->
        {:ok, select_active_cases(person, relevance_date, :input_needed)}

      {[person | _others], _no_matches} ->
        {:ok, select_active_cases(person, relevance_date, :input_needed)}

      {[], [person | _others]} ->
        {:ok, select_active_cases(person, relevance_date, :input_needed)}
    end
  end

  defp find_person_by_phone(phone, relevance_date)
  defp find_person_by_phone(nil, _relevance_date), do: :error
  defp find_person_by_phone("", _relevance_date), do: :error

  defp find_person_by_phone(phone, relevance_date) do
    [
      CaseContext.list_people_by_contact_method(:mobile, phone),
      CaseContext.list_people_by_contact_method(:landline, phone)
    ]
    |> List.flatten()
    |> Enum.uniq_by(& &1.uuid)
    |> preload_person()
    |> case do
      [] -> :error
      [person | _others] -> {:ok, select_active_cases(person, relevance_date, :input_needed)}
    end
  end

  defp find_person_by_email(email, relevance_date)
  defp find_person_by_email(nil, _relevance_date), do: :error
  defp find_person_by_email("", _relevance_date), do: :error

  defp find_person_by_email(email, relevance_date) do
    :email
    |> CaseContext.list_people_by_contact_method(email)
    |> preload_person()
    |> case do
      [] -> :error
      [person | _others] -> {:ok, select_active_cases(person, relevance_date, :input_needed)}
    end
  end

  defp select_active_cases(
         %Person{cases: cases} = person,
         relevance_date,
         max_certainty \\ :certain
       ) do
    was_index =
      cases != [] and
        Enum.any?(cases, fn case ->
          Enum.any?(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1))
        end)

    cases
    |> Enum.filter(fn %Case{inserted_at: inserted_at, phases: phases} ->
      phase_active =
        phases
        |> Enum.filter(& &1.quarantine_order)
        |> Enum.map(&Date.range(&1.start, &1.end))
        |> Enum.any?(&Enum.member?(&1, relevance_date))

      case_recent = abs(Date.diff(DateTime.to_date(inserted_at), relevance_date)) < 10

      phase_active or case_recent
    end)
    |> case do
      [] when was_index ->
        {:input_needed,
         %Planner.Action.SelectCase{case: nil, person: person, suppress_quarantine: true}}

      [] ->
        {max_certainty, %Planner.Action.SelectCase{case: nil, person: person}}

      [case] ->
        {max_certainty, %Planner.Action.SelectCase{case: case, person: person}}

      [case, _other_case | _rest] ->
        {Planner.limit_certainty(:uncertain, max_certainty),
         %Planner.Action.SelectCase{case: case, person: person}}
    end
  end

  defp person_phone_matches?(person, phone)
  defp person_phone_matches?(_person, nil), do: false
  defp person_phone_matches?(_person, ""), do: false

  defp person_phone_matches?(%Person{contact_methods: contact_methods}, phone) do
    with {:ok, parsed_number} <- ExPhoneNumber.parse(phone, @origin_country),
         formatted_phone <- ExPhoneNumber.Formatting.format(parsed_number, :international) do
      Enum.any?(contact_methods, &match?(%ContactMethod{value: ^formatted_phone}, &1))
    else
      {:error, _reason} -> false
    end
  end

  @spec save(
          row :: Row.t(),
          params :: Planner.Generator.params(),
          preceeding_action_plan :: [Planner.Action.t()]
        ) ::
          {Planner.certainty(), Planner.Action.t()}
  def save(_row, _params, _preceeding_steps), do: {:certain, %Planner.Action.Save{}}

  @spec patch_phase(
          row :: Row.t(),
          params :: Planner.Generator.params(),
          preceeding_action_plan :: [Planner.Action.t()]
        ) ::
          {Planner.certainty(), Planner.Action.t()}
  def patch_phase(_row, _params, preceeding_steps) do
    {:certain,
     case Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.SelectCase{}}, &1)) do
       {_certainty, %Planner.Action.SelectCase{case: nil, suppress_quarantine: true}} ->
         %Planner.Action.PatchPhases{action: :append, phase_type: :index, quarantine_order: false}

       {_certainty, %Planner.Action.SelectCase{case: nil}} ->
         %Planner.Action.PatchPhases{action: :append, phase_type: :index}

       {_certainty,
        %Planner.Action.SelectCase{
          case: %Case{phases: phases},
          suppress_quarantine: suppress_quarantine
        }} ->
         if Enum.any?(phases, &match?(%Case.Phase{details: %Case.Phase.Index{}}, &1)) do
           %Planner.Action.PatchPhases{action: :skip, phase_type: :index}
         else
           if suppress_quarantine do
             %Planner.Action.PatchPhases{
               action: :append,
               phase_type: :index,
               quarantine_order: false
             }
           else
             %Planner.Action.PatchPhases{action: :append, phase_type: :index}
           end
         end
     end}
  end

  @spec patch_extenal_references(field_mapping :: field_mapping) ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def patch_extenal_references(field_mapping) do
    fn _row, %{changes: changes}, _preceeding_steps ->
      external_references =
        @external_reference_mapping
        |> Enum.map(fn {subject, type, common_field_identifier} ->
          {subject, type, Row.get_change_field(changes, [field_mapping[common_field_identifier]])}
        end)
        |> Enum.reject(&match?({_subject, _type, nil}, &1))

      {:certain, %Planner.Action.PatchExternalReferences{references: external_references}}
    end
  end

  @spec patch_person(field_mapping :: field_mapping) ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def patch_person(field_mapping) do
    fn _row, %{changes: changes}, _preceeding_steps ->
      person_attrs =
        @person_field_path
        |> Enum.map(fn {common_field_identifier, destination_path} ->
          {field_mapping[common_field_identifier], destination_path}
        end)
        |> Enum.map(fn {field_name, destination_path} ->
          {destination_path, Row.get_change_field(changes, [field_name])}
        end)
        |> Enum.reject(&match?({_path, nil}, &1))
        |> Enum.reject(&match?({_path, ""}, &1))
        |> Enum.map(&normalize_person_data/1)
        |> extract_field_changes()

      case get_invalid_changes(person_attrs) do
        [] ->
          {:certain,
           %Planner.Action.PatchPerson{
             person_attrs: person_attrs,
             invalid_changes: []
           }}

        invalid_changes ->
          {:input_needed,
           %Planner.Action.PatchPerson{
             person_attrs: person_attrs,
             invalid_changes: invalid_changes
           }}
      end
    end
  end

  defp get_invalid_changes(person_attrs),
    do:
      person_attrs
      |> Enum.map(fn
        {:email, email} ->
          if EmailChecker.valid?(email) do
            nil
          else
            :email
          end

        {:address, address} ->
          case Address.changeset(%Address{}, address).errors do
            [subdivision: {"is invalid", _}] -> :subdivision
            _others -> nil
          end

        {:phone, phone} ->
          case validate_and_format_phone(phone) do
            {true, _field, _formatted} -> nil
            {false, _field, _formatted} -> :phone
          end

        _others ->
          nil
      end)
      |> Enum.reject(&is_nil/1)

  @spec normalize_person_data({path :: [atom], value :: term}) ::
          {path :: [atom], value :: term}
  defp normalize_person_data(field)

  defp normalize_person_data({[:sex] = path, sex}) when is_binary(sex) do
    {path,
     cond do
       String.downcase(sex) == String.downcase("männlich") -> :male
       String.downcase(sex) == String.downcase("weiblich") -> :female
       String.downcase(sex) == String.downcase("anders") -> :other
       true -> nil
     end}
  end

  defp normalize_person_data({[:patient_id], value}) do
    [{[:external_references, 0, :type], :ism_patient}, {[:external_references, 0, :value], value}]
  end

  defp normalize_person_data({[:birth_date] = path, date}) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> {path, date}
      {:error, _reason} -> {path, nil}
    end
  end

  defp normalize_person_data({[:phone] = path, value}) when is_binary(value) do
    case validate_and_format_phone(value) do
      {true, nil, nil} -> {path, nil}
      {true, field, formatted} -> [{[field], formatted}]
      {false, nil, nil} -> {path, value}
    end
  end

  defp normalize_person_data({path, country} = field) when is_binary(country) do
    with :country <- List.last(path),
         locale = HygeiaCldr.get_locale().language,
         upcase_country = String.upcase(country),
         downcase_country = String.downcase(country),
         country_ids = Cadastre.Country.ids(),
         false <- upcase_country in country_ids,
         %{^downcase_country => code} <-
           Map.new(
             country_ids,
             &{&1 |> Cadastre.Country.new() |> Cadastre.Country.name(locale) |> String.downcase(),
              &1}
           ) do
      {path, code}
    else
      field_name when is_atom(field_name) -> field
      true -> field
      %{} -> {path, nil}
    end
  end

  defp normalize_person_data({path, value}) do
    if List.last(path) == :zip do
      {path, to_string(value)}
    else
      {path, value}
    end
  end

  defp validate_and_format_phone(phone)
  defp validate_and_format_phone(nil), do: {true, nil, nil}

  defp validate_and_format_phone(value) do
    with {:ok, parsed_number} <-
           ExPhoneNumber.parse(value, @origin_country),
         formatted_phone <- ExPhoneNumber.Formatting.format(parsed_number, :international),
         {:ok, parsed_number} <- ExPhoneNumber.parse(formatted_phone, @origin_country),
         true <- ExPhoneNumber.is_valid_number?(parsed_number) do
      field =
        case ExPhoneNumber.Validation.get_number_type(parsed_number) do
          :mobile -> :mobile
          :fixed_line_or_mobile -> :mobile
          _other -> :landline
        end

      {true, field, formatted_phone}
    else
      {:error, _reason} -> {false, nil, nil}
      false -> {false, nil, nil}
    end
  end

  @spec extract_field_changes(field :: [field | [field]]) :: map
        when field: {path :: [atom], value :: term}
  def extract_field_changes(fields) do
    fields
    |> List.flatten()
    |> Enum.reject(&match?({_path, nil}, &1))
    |> Enum.map(fn {path, value} ->
      {Enum.map(path, &Access.key(&1, %{})), value}
    end)
    |> Enum.reduce(%{}, fn {path, value}, acc ->
      put_in(acc, path, value)
    end)
  end

  @spec patch_tests(field_mapping :: field_mapping) ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def patch_tests(field_mapping) do
    fn row, %{data: data}, preceeding_steps ->
      test_attrs =
        @test_field_path
        |> Enum.map(fn {common_field_identifier, destination_path} ->
          {field_mapping[common_field_identifier], destination_path}
        end)
        |> Enum.map(fn {field_name, destination_path} ->
          {destination_path, Row.get_change_field(data, [field_name])}
        end)
        |> Enum.reject(&match?({_path, nil}, &1))
        |> Enum.map(&normalize_test_data/1)
        |> extract_field_changes()

      reference = Row.get_data_field(row, [field_mapping[:test_reference]])

      action =
        case Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.SelectCase{}}, &1)) do
          {_certainty, %Planner.Action.SelectCase{case: nil}} ->
            :append

          {_certainty, %Planner.Action.SelectCase{case: %Case{tests: tests}}} ->
            if Enum.any?(tests, &match?(%Test{reference: ^reference}, &1)),
              do: :patch,
              else: :append
        end

      {:certain,
       %Planner.Action.PatchTests{reference: reference, action: action, test_attrs: test_attrs}}
    end
  end

  @spec normalize_test_data({path :: [atom], value :: term}) ::
          {path :: [atom], value :: term}
  defp normalize_test_data(field)

  defp normalize_test_data({[:result] = path, result}) when is_binary(result) do
    {path,
     cond do
       String.downcase(result) == "positiv" -> :positive
       String.downcase(result) == "negativ" -> :negative
       String.downcase(result) == "nicht bestimmbar" -> :inconclusive
       true -> nil
     end}
  end

  defp normalize_test_data({[:kind] = path, [kind | _others]}) when is_binary(kind),
    do: normalize_test_data({path, kind})

  defp normalize_test_data({[:kind] = path, kind}) when is_binary(kind) do
    {path,
     cond do
       String.downcase(kind) == String.downcase("Antigen ++ Schnelltest") -> :antigen_quick
       String.downcase(kind) == String.downcase("Antigen ++ unbestimmt") -> :antigen_quick
       String.downcase(kind) == String.downcase("Nukleinsäure ++ PCR") -> :pcr
       String.downcase(kind) == String.downcase("PCR") -> :pcr
       String.downcase(kind) == String.downcase("Serologie") -> :serology
       true -> nil
     end}
  end

  defp normalize_test_data({path, date})
       when is_binary(date) and path in [[:tested_at], [:laboratory_reported_at]] do
    case Date.from_iso8601(date) do
      {:ok, date} -> {path, date}
      {:error, _reason} -> {path, nil}
    end
  end

  defp normalize_test_data({path, value}) do
    if List.last(path) == :zip do
      {path, to_string(value)}
    else
      {path, value}
    end
  end

  @spec patch_assignee(
          row :: Row.t(),
          params :: Planner.Generator.params(),
          preceeding_action_plan :: [Planner.Action.t()]
        ) ::
          {Planner.certainty(), Planner.Action.t()}
  def patch_assignee(
        %Row{
          import: %Import{
            default_supervisor_uuid: default_supervisor_uuid,
            default_tracer_uuid: default_tracer_uuid,
            tenant_uuid: tenant_uuid
          }
        },
        _params,
        preceeding_steps
      ) do
    {_certainty, %Planner.Action.ChooseTenant{tenant: tenant}} =
      Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.ChooseTenant{}}, &1))

    # Reset Default if Tenant of Import does not match Tenant of Row
    {default_tracer_uuid, default_supervisor_uuid} =
      case tenant do
        %Tenant{uuid: ^tenant_uuid} -> {default_tracer_uuid, default_supervisor_uuid}
        %Tenant{} -> {nil, nil}
      end

    {:certain,
     case Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.PatchPhases{}}, &1)) do
       {_certainty, %Planner.Action.PatchPhases{action: :skip}} ->
         %Planner.Action.PatchAssignee{action: :skip}

       {_certainty, %Planner.Action.PatchPhases{action: :append}} ->
         %Planner.Action.PatchAssignee{
           action: :change,
           tracer_uuid: default_tracer_uuid,
           supervisor_uuid: default_supervisor_uuid
         }
     end}
  end

  @spec patch_status(
          row :: Row.t(),
          params :: Planner.Generator.params(),
          preceeding_action_plan :: [Planner.Action.t()]
        ) ::
          {Planner.certainty(), Planner.Action.t()}
  def patch_status(_row, _params, preceeding_steps) do
    {:certain,
     case Enum.find(preceeding_steps, &match?({_certainty, %Planner.Action.PatchPhases{}}, &1)) do
       {_certainty, %Planner.Action.PatchPhases{action: :skip}} ->
         %Planner.Action.PatchStatus{action: :skip}

       {_certainty, %Planner.Action.PatchPhases{action: :append}} ->
         if Enum.find(
              preceeding_steps,
              &match?({_certainty, %Planner.Action.SelectCase{suppress_quarantine: true}}, &1)
            ) do
           %Planner.Action.PatchStatus{action: :change, status: :done}
         else
           %Planner.Action.PatchStatus{action: :change, status: :first_contact}
         end
     end}
  end

  @spec add_note ::
          (row :: Row.t(),
           params :: Planner.Generator.params(),
           preceeding_action_plan :: [Planner.Action.t()] ->
             {Planner.certainty(), Planner.Action.t()})
  def add_note do
    fn %Row{}, _params, _preceeding_steps ->
      {:certain, %Planner.Action.AddNote{action: :skip}}
    end
  end

  defp preload_case(case),
    do:
      Repo.preload(case, person: [], tenant: [], tests: [], hospitalizations: [], auto_tracing: [])

  defp preload_person(person),
    do:
      Repo.preload(person, cases: [tenant: [], tests: [], hospitalizations: [], auto_tracing: []])
end
