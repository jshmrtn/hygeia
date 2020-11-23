defmodule HygeiaWeb.CaseLive.Create do
  @moduledoc false

  import HygeiaGettext
  import Phoenix.LiveView

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case.ContactMethod
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreateIndex.CreateSchema

  @spec update_person_changeset(
          changeset :: Ecto.Changeset.t(),
          person :: Person.t()
        ) ::
          Ecto.Changeset.t()
  def update_person_changeset(changeset, person) do
    changeset
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreatePersonSchema.changeset(%{
      accepted_duplicate: true,
      accepted_duplicate_uuid: person.uuid,
      accepted_duplicate_human_readable_id: person.human_readable_id,
      first_name: person.first_name,
      last_name: person.last_name,
      tenant_uuid: person.tenant_uuid,
      mobile:
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :mobile, value: value} -> value
          _other -> false
        end),
      landline:
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :landline, value: value} -> value
          _other -> false
        end),
      email:
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :email, value: value} -> value
          _other -> false
        end),
      sex: person.sex,
      birth_date: person.birth_date,
      employer:
        case person.employers do
          [%{name: name}] -> name
          _other -> nil
        end,
      address: Map.from_struct(person.address)
    })
  end

  @spec save_or_load_person_schema(
          schema :: %CreatePersonSchema{},
          socket :: Phoenix.LiveView.Socket.t(),
          global_changeset :: Ecto.Changeset.t()
        ) :: {Person.t(), User.t(), User.t()}
  def save_or_load_person_schema(
        %CreatePersonSchema{
          accepted_duplicate_uuid: nil,
          tenant_uuid: tenant_uuid,
          tracer_uuid: tracer_uuid,
          supervisor_uuid: supervisor_uuid
        } = schema,
        socket,
        global_changeset
      ) do
    tenant_uuid =
      case tenant_uuid do
        nil -> Ecto.Changeset.fetch_field!(global_changeset, :default_tenant_uuid)
        other -> other
      end

    tracer_uuid =
      case tracer_uuid do
        nil -> Ecto.Changeset.fetch_field!(global_changeset, :default_tracer_uuid)
        other -> other
      end

    supervisor_uuid =
      case supervisor_uuid do
        nil -> Ecto.Changeset.fetch_field!(global_changeset, :default_supervisor_uuid)
        other -> other
      end

    tenant = Enum.find(socket.assigns.tenants, &match?(%Tenant{uuid: ^tenant_uuid}, &1))

    tracer = Enum.find(socket.assigns.tracer_users, &match?(%User{uuid: ^tracer_uuid}, &1))

    supervisor =
      Enum.find(socket.assigns.supervisor_users, &match?(%User{uuid: ^supervisor_uuid}, &1))

    person_attrs =
      CreatePersonSchema.to_person_attrs(
        schema,
        Ecto.Changeset.fetch_field!(global_changeset, :default_country)
      )

    {:ok, person} = CaseContext.create_person(tenant, person_attrs)

    {person, supervisor, tracer}
  end

  def save_or_load_person_schema(
        %CreatePersonSchema{
          accepted_duplicate_uuid: person_uuid,
          tracer_uuid: tracer_uuid,
          supervisor_uuid: supervisor_uuid
        },
        socket,
        global_changeset
      ) do
    tracer_uuid =
      case tracer_uuid do
        nil -> Ecto.Changeset.fetch_field!(global_changeset, :default_tracer_uuid)
        other -> other
      end

    supervisor_uuid =
      case supervisor_uuid do
        nil -> Ecto.Changeset.fetch_field!(global_changeset, :default_supervisor_uuid)
        other -> other
      end

    tracer = Enum.find(socket.assigns.tracer_users, &match?(%User{uuid: ^tracer_uuid}, &1))

    supervisor =
      Enum.find(socket.assigns.supervisor_users, &match?(%User{uuid: ^supervisor_uuid}, &1))

    person = CaseContext.get_person!(person_uuid)

    {person, supervisor, tracer}
  end

  @spec fetch_tenant(field :: {key :: [atom], value :: term}, tenants :: [Tenant.t()]) ::
          {key :: [atom], value :: term}
  def fetch_tenant({[:tenant], tenant_name}, tenants),
    do: {:tenant, Enum.find(tenants, &match?(%Tenant{name: ^tenant_name}, &1))}

  def fetch_tenant(field, _tenants), do: field

  @spec fetch_test_result(field :: {key :: [atom], value :: term}) ::
          {key :: [atom], value :: term}
  def fetch_test_result({[:clinical, :result], kind}) do
    {[:clinical, :result],
     cond do
       String.downcase(kind) == String.downcase("positive") -> :positive
       String.downcase(kind) == String.downcase("negative") -> :negative
       String.downcase(kind) == String.downcase(gettext("positive")) -> :positive
       String.downcase(kind) == String.downcase(gettext("negative")) -> :negative
       true -> nil
     end}
  end

  def fetch_test_result(field), do: field

  @spec fetch_test_kind(field :: {key :: [atom], value :: term}) :: {key :: [atom], value :: term}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def fetch_test_kind({[:clinical, :test_kind], kind}) do
    {[:clinical, :test_kind],
     cond do
       String.downcase(kind) == String.downcase("Antigen ++ Schnelltest") -> :quick
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

  def fetch_test_kind(field), do: field

  @spec import_into_changeset(changeset :: Ecto.Changeset.t(), data :: [map]) ::
          Ecto.Changeset.t()
  def import_into_changeset(changeset, data) do
    changeset
    |> Ecto.Changeset.put_embed(
      :people,
      Ecto.Changeset.get_change(changeset, :people, []) ++
        (data
         |> Stream.map(&CreatePersonSchema.changeset(%CreatePersonSchema{}, &1))
         |> Enum.to_list())
    )
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreateSchema.validate_changeset()
  end

  @spec normalize_import_field({key :: [atom], value :: term}, [Tenant.t()]) ::
          {key :: [atom], value :: term}
  def normalize_import_field(field, tenants) do
    field
    |> fetch_tenant(tenants)
    |> fetch_test_kind()
    |> fetch_test_result()
  end

  @spec decline_duplicate(changeset :: Ecto.Changeset.t(), person_changeset_uuid :: String.t()) ::
          Ecto.Changeset.t()
  def decline_duplicate(changeset, person_changeset_uuid) do
    changeset
    |> Ecto.Changeset.put_embed(
      :people,
      changeset
      |> Ecto.Changeset.get_change(:people, [])
      |> Enum.map(fn
        %Ecto.Changeset{changes: %{uuid: ^person_changeset_uuid}} = changeset ->
          changeset
          |> Map.put(:errors, [])
          |> Map.put(:valid?, true)
          |> CreatePersonSchema.changeset(%{
            accepted_duplicate: false,
            accepted_duplicate_uuid: nil
          })

        changeset ->
          changeset
      end)
    )
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreateSchema.validate_changeset()
  end

  @spec accept_duplicate(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: String.t(),
          person :: Person.t()
        ) :: Ecto.Changeset.t()
  def accept_duplicate(changeset, person_changeset_uuid, person) do
    changeset
    |> Ecto.Changeset.put_embed(
      :people,
      changeset
      |> Ecto.Changeset.get_change(:people, [])
      |> Enum.map(fn
        %Ecto.Changeset{changes: %{uuid: ^person_changeset_uuid}} = changeset ->
          update_person_changeset(changeset, person)

        changeset ->
          changeset
      end)
    )
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreateSchema.validate_changeset()
  end

  @spec remove_person(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: String.t()
        ) :: Ecto.Changeset.t()
  def remove_person(changeset, person_changeset_uuid) do
    changeset
    |> Ecto.Changeset.put_embed(
      :people,
      changeset
      |> Ecto.Changeset.get_change(:people, [])
      |> Enum.reject(&match?(%Ecto.Changeset{changes: %{uuid: ^person_changeset_uuid}}, &1))
    )
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreateSchema.validate_changeset()
  end

  @spec handle_save_success(socket :: Phoenix.LiveView.Socket.t(), schema :: atom) ::
          Phoenix.LiveView.Socket.t()
  def handle_save_success(socket, schema) do
    case socket.assigns.return_to do
      nil ->
        assign(socket,
          changeset:
            socket.assigns.changeset
            |> Ecto.Changeset.put_embed(:people, [])
            |> Map.put(:errors, [])
            |> Map.put(:valid?, true)
            |> schema.validate_changeset(),
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
      "Patient Telefon" => [:mobile],
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
      "Auftraggeber Ort" => [:clinical, :sponsor, :address, :place]
    }
end
