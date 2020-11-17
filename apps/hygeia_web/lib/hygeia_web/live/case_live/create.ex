defmodule HygeiaWeb.CaseLive.Create do
  @moduledoc false

  import HygeiaGettext

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
        end)
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

    person_attrs = CreatePersonSchema.to_person_attrs(schema)

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

    tracer = Enum.find(socket.assigns.users, &match?(%User{uuid: ^tracer_uuid}, &1))

    supervisor = Enum.find(socket.assigns.users, &match?(%User{uuid: ^supervisor_uuid}, &1))

    person = CaseContext.get_person!(person_uuid)

    {person, supervisor, tracer}
  end

  @spec fetch_tenant(row :: map, tenants :: [Tenant.t()]) :: map
  def fetch_tenant(row, tenants) do
    row
    |> Enum.map(fn
      {:tenant, tenant_name} ->
        {:tenant, Enum.find(tenants, &match?(%Tenant{name: ^tenant_name}, &1))}

      other ->
        other
    end)
    |> Enum.reject(&match?({:tenant, nil}, &1))
    |> Enum.map(fn
      {:tenant, %Tenant{uuid: tenant_uuid}} -> {:tenant_uuid, tenant_uuid}
      other -> other
    end)
    |> Map.new()
  end

  @spec fetch_test_kind(row :: map) :: map
  def fetch_test_kind(row) do
    row
    |> Enum.map(fn
      {:test_kind, kind} ->
        {:test_kind,
         cond do
           String.downcase(kind) == String.downcase("PCR") -> :pcr
           String.downcase(kind) == String.downcase("Serology") -> :serology
           String.downcase(kind) == String.downcase(gettext("PCR")) -> :pcr
           String.downcase(kind) == String.downcase(gettext("Serology")) -> :serology
           true -> nil
         end}

      other ->
        other
    end)
    |> Enum.reject(&match?({:test_kind, nil}, &1))
    |> Map.new()
  end

  @spec fetch_test_result(row :: map) :: map
  def fetch_test_result(row) do
    row
    |> Enum.map(fn
      {:test_result, kind} ->
        {:test_result,
         cond do
           String.downcase(kind) == String.downcase("positive") -> :positive
           String.downcase(kind) == String.downcase("negative") -> :negative
           String.downcase(kind) == String.downcase(gettext("positive")) -> :positive
           String.downcase(kind) == String.downcase(gettext("negative")) -> :negative
           true -> nil
         end}

      other ->
        other
    end)
    |> Enum.reject(&match?({:test_result, nil}, &1))
    |> Map.new()
  end

  @spec import_into_changeset(
          changeset :: Ecto.Changeset.t(),
          data :: [map],
          tenants :: [Tenant.t()]
        ) :: Ecto.Changeset.t()
  def import_into_changeset(changeset, data, tenants) do
    changeset
    |> Ecto.Changeset.put_embed(
      :people,
      Ecto.Changeset.get_change(changeset, :people, []) ++
        (data
         |> Stream.map(&fetch_tenant(&1, tenants))
         |> Stream.map(&fetch_test_kind/1)
         |> Stream.map(&fetch_test_result/1)
         |> Stream.map(&CreatePersonSchema.changeset(%CreatePersonSchema{}, &1))
         |> Enum.to_list())
    )
    |> Map.put(:errors, [])
    |> Map.put(:valid?, true)
    |> CreateSchema.validate_changeset()
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

  @spec get_csv_key_mapping() :: map
  def get_csv_key_mapping,
    do: %{
      "first name" => :first_name,
      gettext("First name") => :first_name,
      "last name" => :last_name,
      gettext("Last name") => :last_name,
      "mobile" => :mobile,
      "mobile_phone" => :mobile,
      gettext("Mobile Phone") => :mobile,
      "landline" => :landline,
      "landline phone" => :landline,
      gettext("Landline") => :landline,
      "email" => :email,
      gettext("Email") => :email,
      "tenant" => :tenant,
      gettext("Tenant") => :tenant,
      "employer" => :employer,
      gettext("Employer") => :employer,
      "test_date" => :test_date,
      gettext("Test date") => :test_date,
      "test_laboratory_report" => :test_laboratory_report,
      gettext("Laboratory report date") => :test_laboratory_report,
      "test_kind" => :test_kind,
      gettext("Test Kind") => :test_kind,
      "test_result" => :test_result,
      gettext("Test Result") => :test_result
    }
end
