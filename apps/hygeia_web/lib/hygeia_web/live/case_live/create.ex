defmodule HygeiaWeb.CaseLive.Create do
  @moduledoc false

  import HygeiaGettext
  import HygeiaWeb.Helpers.Changeset
  import Phoenix.LiveView

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant

  @origin_country Application.compile_env!(:hygeia, [:phone_number_parsing_origin_country])

  @spec get_person_changes(person :: Person.t()) :: Ecto.Changeset.t()
  def get_person_changes(person) do
    person = Repo.preload(person, affiliations: [organisation: []])

    drop_empty_recursively_and_remove_uuid(%{
      "accepted_duplicate" => true,
      "accepted_duplicate_uuid" => person.uuid,
      "accepted_duplicate_human_readable_id" => person.human_readable_id,
      "first_name" => person.first_name,
      "last_name" => person.last_name,
      "tenant_uuid" => person.tenant_uuid,
      "mobile" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :mobile, value: value} -> value
          _other -> false
        end),
      "landline" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :landline, value: value} -> value
          _other -> false
        end),
      "email" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :email, value: value} -> value
          _other -> false
        end),
      "sex" => person.sex,
      "birth_date" => person.birth_date,
      "employer" =>
        case person.affiliations do
          [%Affiliation{organisation: %Organisation{name: name}} | _] -> name
          [%Affiliation{comment: comment} | _] -> comment
          _other -> nil
        end,
      "address" => person.address |> Ecto.embedded_dump(:json) |> recursive_string_keys()
    })
  end

  @spec get_case_changes(person :: Case.t(), schema_module :: module()) :: Ecto.Changeset.t()
  def get_case_changes(case, schema_module) do
    phase_detail_module =
      case schema_module do
        HygeiaWeb.CaseLive.CreateIndex.CreateSchema -> Case.Phase.Index
        HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema -> Case.Phase.PossibleIndex
      end

    keep_assignees =
      Enum.any?(case.phases, &match?(%Case.Phase{details: %^phase_detail_module{}}, &1))

    drop_empty_recursively_and_remove_uuid(%{
      "accepted_duplicate" => true,
      "accepted_duplicate_case_uuid" => case.uuid,
      "clinical" =>
        case case.clinical do
          nil -> nil
          clinical -> clinical |> Ecto.embedded_dump(:json) |> recursive_string_keys()
        end,
      "tracer_uuid" => if(keep_assignees, do: case.tracer_uuid),
      "supervisor_uuid" => if(keep_assignees, do: case.supervisor_uuid),
      "ism_case_id" =>
        Enum.find_value(case.external_references, fn
          %ExternalReference{type: :ism_case, value: value} -> value
          _other -> false
        end),
      "ism_report_id" =>
        Enum.find_value(case.external_references, fn
          %ExternalReference{type: :ism_report, value: value} -> value
          _other -> false
        end)
    })
  end

  @spec drop_empty_recursively_and_remove_uuid(input :: term) :: term
  def drop_empty_recursively_and_remove_uuid(map) when is_map(map) and not is_struct(map),
    do:
      map
      |> Enum.reject(&match?({:uuid, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Enum.map(&{elem(&1, 0), drop_empty_recursively_and_remove_uuid(elem(&1, 1))})
      |> Map.new()

  def drop_empty_recursively_and_remove_uuid(list) when is_list(list),
    do: list |> Enum.reject(&is_nil/1) |> Enum.map(&drop_empty_recursively_and_remove_uuid/1)

  def drop_empty_recursively_and_remove_uuid(other), do: other

  @spec fetch_tenant(field :: {key :: [atom], value :: term}, tenants :: [Tenant.t()]) ::
          {key :: [atom], value :: term}
  def fetch_tenant({[:tenant], tenant_name}, tenants) when is_binary(tenant_name) do
    search = String.downcase(tenant_name)

    {[:tenant_uuid],
     tenants
     |> Enum.flat_map(fn
       %Tenant{uuid: uuid, name: name, short_name: nil} ->
         [{String.downcase(name), uuid}]

       %Tenant{uuid: uuid, name: name, short_name: short_name} ->
         [{String.downcase(name), uuid}, {String.downcase(short_name), uuid}]
     end)
     |> Enum.find_value(fn
       {^search, uuid} -> uuid
       _other -> false
     end)}
  end

  def fetch_tenant(field, _tenants), do: field

  @spec fetch_test_result(field :: {key :: [atom], value :: term}) ::
          {key :: [atom], value :: term}
  def fetch_test_result({[:clinical, :result], result}) when is_binary(result) do
    {[:clinical, :result],
     cond do
       String.downcase(result) == String.downcase("positive") -> :positive
       String.downcase(result) == String.downcase("negative") -> :negative
       String.downcase(result) == String.downcase(gettext("positive")) -> :positive
       String.downcase(result) == String.downcase(gettext("negative")) -> :negative
       true -> nil
     end}
  end

  def fetch_test_result({[:clinical, :positive_result_count], count}) when is_binary(count) do
    case Integer.parse(count) do
      {count, ""} when count > 0 -> {[:clinical, :result], :positive}
      _other -> {[:clinical, :result], :negative}
    end
  end

  def fetch_test_result(field), do: field

  @spec fetch_sex(field :: {key :: [atom], value :: term}) :: {key :: [atom], value :: term}
  def fetch_sex({[:sex], sex}) when is_binary(sex) do
    {[:sex],
     cond do
       String.downcase(sex) == String.downcase("Male") -> :male
       String.downcase(sex) == String.downcase("Female") -> :female
       String.downcase(sex) == String.downcase("Other") -> :other
       String.downcase(sex) == String.downcase(pgettext("Sex", "Male")) -> :male
       String.downcase(sex) == String.downcase(pgettext("Sex", "Female")) -> :female
       String.downcase(sex) == String.downcase(pgettext("Sex", "Other")) -> :other
       true -> nil
     end}
  end

  def fetch_sex(field), do: field

  @spec fetch_country(field :: {key :: [atom], value :: term}) :: {key :: [atom], value :: term}
  def fetch_country({path, country} = field) when is_binary(country) do
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

  def fetch_country(field), do: field

  @spec fetch_test_kind(field :: {key :: [atom], value :: term}) :: {key :: [atom], value :: term}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def fetch_test_kind({[:clinical, :test_kind], kind}) when is_binary(kind) do
    {[:clinical, :test_kind],
     cond do
       String.downcase(kind) == String.downcase("Antigen ++ Schnelltest") -> :antigen_quick
       String.downcase(kind) == String.downcase("quick") -> :quick
       String.downcase(kind) == String.downcase(gettext("quick")) -> :quick
       String.downcase(kind) == String.downcase("Nukleinsäure ++ PCR") -> :pcr
       String.downcase(kind) == String.downcase("pcr") -> :pcr
       String.downcase(kind) == String.downcase(gettext("PCR")) -> :pcr
       String.downcase(kind) == String.downcase(gettext("serology")) -> :serology
       String.downcase(kind) == String.downcase("serology") -> :serology
       true -> nil
     end}
  end

  def fetch_test_kind({[:clinical, :test_kind_pcr_count], count} = field) when is_binary(count) do
    case Integer.parse(count) do
      {count, ""} when count > 0 -> {[:clinical, :test_kind], :pcr}
      _other -> field
    end
  end

  def fetch_test_kind({[:clinical, :test_kind_antigen_count], count} = field)
      when is_binary(count) do
    case Integer.parse(count) do
      {count, ""} when count > 0 -> {[:clinical, :test_kind], :antigen_quick}
      _other -> field
    end
  end

  def fetch_test_kind(field), do: field

  @spec decide_phone_kind(field :: {key :: [atom], value :: term}) ::
          {key :: [atom], value :: term}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def decide_phone_kind({[:phone], value}) when is_binary(value) do
    with {:ok, parsed_number} <-
           ExPhoneNumber.parse(value, @origin_country),
         true <- ExPhoneNumber.is_valid_number?(parsed_number),
         phone_number_type when phone_number_type in [:fixed_line, :voip] <-
           ExPhoneNumber.Validation.get_number_type(parsed_number) do
      {[:landline], value}
    else
      _other -> {[:mobile], value}
    end
  end

  def decide_phone_kind(field), do: field

  @spec import_into_changeset(
          changeset :: Ecto.Changeset.t(),
          data :: [map],
          schema_module :: atom
        ) ::
          Ecto.Changeset.t()
  def import_into_changeset(changeset, data, schema_module) do
    data =
      data
      |> Enum.map(&Map.put(&1, :uuid, Ecto.UUID.generate()))
      |> recursive_string_keys()

    schema_module.changeset(
      changeset.data,
      update_changeset_param_relation(changeset, :people, [:uuid], &Enum.concat(&1, data))
    )
  end

  @spec normalize_import_field({key :: [atom], value :: term}, [Tenant.t()]) ::
          {key :: [atom], value :: term}
  def normalize_import_field(field, tenants) do
    field
    |> fetch_tenant(tenants)
    |> fetch_test_kind()
    |> fetch_test_result()
    |> fetch_sex()
    |> fetch_country()
    |> decide_phone_kind()
  end

  @spec decline_duplicate(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          schema_module :: atom
        ) ::
          Ecto.Changeset.t()
  def decline_duplicate(changeset, person_changeset_uuid, schema_module),
    do:
      schema_module.changeset(
        changeset.data,
        changeset_update_params_by_id(
          changeset,
          :people,
          %{uuid: person_changeset_uuid},
          &Map.merge(&1, %{
            "accepted_duplicate" => false,
            "accepted_duplicate_uuid" => nil
          })
        )
      )

  @spec accept_duplicate(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          person :: Person.t() | {Case.t(), Person.t()},
          schema_module :: atom
        ) :: Ecto.Changeset.t()
  def accept_duplicate(changeset, person_changeset_uuid, person_or_changeset, schema_module) do
    schema_module.changeset(
      changeset.data,
      changeset_update_params_by_id(
        changeset,
        :people,
        %{uuid: person_changeset_uuid},
        fn old_params ->
          Map.merge(
            old_params,
            case person_or_changeset do
              {case, person} ->
                Map.merge(get_person_changes(person), get_case_changes(case, schema_module))

              person ->
                get_person_changes(person)
            end,
            &recursive_map_merge/3
          )
        end
      )
    )
  end

  @spec remove_person(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          schema_module :: atom
        ) :: Ecto.Changeset.t()
  def remove_person(changeset, person_changeset_uuid, schema_module),
    do:
      schema_module.changeset(
        changeset.data,
        changeset_remove_from_params_by_id(changeset, :people, %{uuid: person_changeset_uuid})
      )

  @spec handle_save_success(socket :: Phoenix.LiveView.Socket.t(), schema :: atom) ::
          Phoenix.LiveView.Socket.t()
  def handle_save_success(socket, schema) do
    case socket.assigns.return_to do
      nil ->
        assign(socket,
          changeset:
            schema.changeset(
              socket.assigns.changeset.data,
              update_changeset_param_relation(
                socket.assigns.changeset,
                :people,
                [:uuid],
                fn _list -> [] end
              )
            ),
          suspected_duplicate_changeset_uuid: nil,
          file: nil
        )

      uri ->
        push_redirect(socket, to: uri)
    end
  end

  @spec get_csv_key_mapping() :: map
  def get_csv_key_mapping,
    do: %{
      "first name" => [:first_name],
      gettext("First name") => [:first_name],
      "last name" => [:last_name],
      gettext("Last name") => [:last_name],
      "mobile" => [:mobile],
      "mobile_phone" => [:mobile],
      gettext("Mobile Phone") => [:mobile],
      "landline" => [:landline],
      "landline phone" => [:landline],
      gettext("Landline") => [:landline],
      "email" => [:email],
      gettext("Email") => [:email],
      "tenant" => [:tenant],
      gettext("Tenant") => [:tenant],
      "employer" => [:employer],
      gettext("Employer") => [:employer],
      "test_date" => [:clinical, :test],
      gettext("Test date") => [:clinical, :test],
      "test_laboratory_report" => [:clinical, :laboratory_report],
      gettext("Laboratory report date") => [:clinical, :laboratory_report],
      "test_kind" => [:clinical, :test_kind],
      gettext("Test Kind") => [:clinical, :test_kind],
      "test_result" => [:clinical, :result],
      gettext("Test Result") => [:clinical, :result],

      # Laboratory Report Names
      "Fall ID" => [:ism_case_id],
      "Meldung ID" => [:ism_report_id],
      "Patient Nachname" => [:last_name],
      "Patient Vorname" => [:first_name],
      "Patient Geburtsdatum" => [:birth_date],
      "Patient Geschlecht" => [:sex],
      "Patient Telefon" => [:phone],
      "Patient Strasse" => [:address, :address],
      "Patient PLZ" => [:address, :zip],
      "Patient Wohnort" => [:address, :place],
      "Patient Kanton" => [:address, :subdivision],
      "Entnahmedatum" => [:clinical, :test],
      "Nachweismethode" => [:clinical, :test_kind],
      "Meldungseingang" => [:clinical, :laboratory_report],
      "Testresultat" => [:clinical, :result],
      "Meldeeinheit Institution" => [:clinical, :reporting_unit, :name],
      "Meldeeinheit Abteilung/Institut" => [:clinical, :reporting_unit, :name],
      "Meldeeinheit Vorname" => [:clinical, :reporting_unit, :name],
      "Meldeeinheit Nachname" => [:clinical, :reporting_unit, :name],
      "Meldeeinheit Strasse" => [:clinical, :reporting_unit, :address, :address],
      "Meldeeinheit PLZ" => [:clinical, :reporting_unit, :address, :zip],
      "Meldeeinheit Ort" => [:clinical, :reporting_unit, :address, :place],
      "Auftraggeber Institution" => [:clinical, :sponsor, :name],
      "Auftraggeber Abteilung/Institut" => [:clinical, :sponsor, :name],
      "Auftraggeber Nachname" => [:clinical, :sponsor, :name],
      "Auftraggeber Vorname" => [:clinical, :sponsor, :name],
      "Auftraggeber Strasse" => [:clinical, :sponsor, :address, :address],
      "Auftraggeber PLZ" => [:clinical, :sponsor, :address, :zip],
      "Auftraggeber Ort" => [:clinical, :sponsor, :address, :place],

      # Laboratory Report (2020-02)
      "manifestationsbeginn" => [:clinical, :symptom_start],
      "eingang1positivertest" => [:clinical, :test],
      "labtestcreationdatetime" => [:clinical, :laboratory_report],
      "falldatum" => [:clinical, :laboratory_report],
      "geburtsdatum" => [:birth_date],
      "geschlecht" => [:sex],
      "telefon" => [:phone],
      "strasse" => [:address, :address],
      "plz" => [:address, :zip],
      "wohnort" => [:address, :place],
      "wohnsitzland" => [:address, :country],
      "land" => [:address, :country],
      "fallkanton" => [:tenant],
      "testspositiv" => [:clinical, :positive_result_count],
      "pcrpositiv" => [:clinical, :test_kind_pcr_count],
      "antigenpositiv" => [:clinical, :test_kind_antigen_count],
      "meldeeinheitklinbefundinstitution" => [:clinical, :reporting_unit, :name],
      "meldeeinheitklinbefundabteilunginstitut" => [:clinical, :reporting_unit, :name],
      "meldeeinheitklinbefundvorname" => [:clinical, :reporting_unit, :name],
      "meldeeinheitklinbefundnachname" => [:clinical, :reporting_unit, :name],
      "meldeeinheitklinbefundplz" => [:clinical, :reporting_unit, :address, :zip],
      "meldeeinheitklinbefundort" => [:clinical, :reporting_unit, :address, :place],
      "laborauftraggeberinstitution" => [:clinical, :sponsor, :name],
      "laborauftraggeberabteilunginstitut" => [:clinical, :sponsor, :name],
      "laborauftraggebernachname" => [:clinical, :sponsor, :name],
      "laborauftraggebervorname" => [:clinical, :sponsor, :name],
      "laborauftraggeberplz" => [:clinical, :sponsor, :address, :zip],
      "laborauftraggeberort" => [:clinical, :sponsor, :address, :place]
    }

  defp recursive_map_merge(_key, %{} = a, %{} = b) when not is_struct(a) and not is_struct(b),
    do: Map.merge(a, b, &recursive_map_merge/3)

  defp recursive_map_merge(_key, _a, b), do: b

  defp recursive_string_keys(%{} = map) when not is_struct(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), recursive_string_keys(value)}
      {key, value} -> {key, recursive_string_keys(value)}
    end)
  end

  defp recursive_string_keys(list) when is_list(list),
    do: Enum.map(list, &recursive_string_keys/1)

  defp recursive_string_keys(other), do: other
end
