defmodule HygeiaWeb.CaseLive.CreateIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.ContactMethod
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User
  alias HygeiaWeb.CaseLive.CreateIndex.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreateIndex.CreateSchema
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    tenants = TenantContext.list_tenants()
    users = UserContext.list_users()
    auth_user = get_auth(socket)

    super(
      params,
      session,
      assign(socket,
        changeset:
          CreateSchema.changeset(%CreateSchema{people: []}, %{
            default_tracer_uuid: auth_user.uuid,
            default_supervisor_uuid: auth_user.uuid
          }),
        tenants: tenants,
        users: users,
        suspected_duplicate_changeset_uuid: nil,
        file: nil
      )
    )
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"create_schema" => create_params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CreateSchema.changeset(%CreateSchema{people: []}, create_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event(
        "select_accepted_duplicate",
        %{"person-uuid" => duplicate_uuid},
        %{assigns: %{suspected_duplicate_changeset_uuid: uuid}} = socket
      ) do
    person = CaseContext.get_person!(duplicate_uuid)

    {:noreply,
     assign(socket,
       changeset:
         socket.assigns.changeset
         |> Ecto.Changeset.put_embed(
           :people,
           socket.assigns.changeset
           |> Ecto.Changeset.get_change(:people, [])
           |> Enum.map(fn
             %Ecto.Changeset{changes: %{uuid: ^uuid}} = changeset ->
               update_person_changeset(changeset, person)

             changeset ->
               changeset
           end)
         )
         |> Map.put(:errors, [])
         |> Map.put(:valid?, true)
         |> CreateSchema.validate_changeset()
     )}
  end

  def handle_event(
        "decline_duplicate",
        _params,
        %{assigns: %{suspected_duplicate_changeset_uuid: uuid}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset:
         socket.assigns.changeset
         |> Ecto.Changeset.put_embed(
           :people,
           socket.assigns.changeset
           |> Ecto.Changeset.get_change(:people, [])
           |> Enum.map(fn
             %Ecto.Changeset{changes: %{uuid: ^uuid}} = changeset ->
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
     )}
  end

  def handle_event("check_duplicate", %{"changeset-uuid" => uuid} = _params, socket) do
    {:noreply, assign(socket, suspected_duplicate_changeset_uuid: uuid)}
  end

  def handle_event("phx-dropzone", ["generate-url", %{"id" => id} = _payload], socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "uploads:#{id}")

    {:noreply, assign(socket, file: %{id: id, url: Routes.upload_url(socket, :upload, id)})}
  end

  def handle_event("phx-dropzone", ["file-status", _payload], socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"create_schema" => create_params}, socket) do
    %CreateSchema{people: []}
    |> CreateSchema.changeset(create_params)
    |> case do
      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}

      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok, cases} =
          Repo.transaction(fn ->
            changeset
            |> Ecto.Changeset.fetch_field!(:people)
            |> Enum.reject(&match?(%CreatePersonSchema{uuid: nil}, &1))
            |> Enum.map(&save_or_load_person_schema(&1, socket, changeset))
            |> Enum.map(&create_case/1)
          end)

        {:noreply,
         socket
         |> put_flash(:info, ngettext("Created Case", "Created %{n} Cases", length(cases)))
         |> assign(
           changeset:
             changeset
             |> Ecto.Changeset.put_embed(:people, [])
             |> Map.put(:errors, [])
             |> Map.put(:valid?, true)
             |> CreateSchema.validate_changeset(),
           suspected_duplicate_changeset_uuid: nil,
           file: nil
         )}
    end
  end

  defp update_person_changeset(changeset, person) do
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

  defp save_or_load_person_schema(
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

    tracer = Enum.find(socket.assigns.users, &match?(%User{uuid: ^tracer_uuid}, &1))

    supervisor = Enum.find(socket.assigns.users, &match?(%User{uuid: ^supervisor_uuid}, &1))

    person_attrs = CreatePersonSchema.to_person_attrs(schema)

    {:ok, person} = CaseContext.create_person(tenant, person_attrs)

    {person, supervisor, tracer}
  end

  defp save_or_load_person_schema(
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

  defp create_case({person, supervisor, tracer}) do
    {:ok, case} =
      CaseContext.create_case(person, %{
        phases: [%{details: %{__type__: :index}}],
        supervisor_uuid: supervisor.uuid,
        tracer_uuid: tracer.uuid
      })

    case
  end

  @impl Phoenix.LiveView
  def handle_info({:upload, data}, socket) do
    key_mapping = get_csv_key_mapping()

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(
        :people,
        Ecto.Changeset.get_change(socket.assigns.changeset, :people, []) ++
          (data
           |> String.split("\n")
           |> Enum.reject(&match?("", &1))
           |> CSV.decode!(headers: true)
           |> Stream.map(&normalize_row(&1, key_mapping))
           |> Stream.map(&fetch_tenant(&1, socket.assigns.tenants))
           |> Stream.map(&CreatePersonSchema.changeset(%CreatePersonSchema{}, &1))
           |> Enum.to_list())
      )
      |> Map.put(:errors, [])
      |> Map.put(:valid?, true)
      |> CreateSchema.validate_changeset()

    {:noreply, assign(socket, changeset: changeset)}
  rescue
    FunctionClauseError -> {:noreply, put_flash(socket, :error, gettext("Could not parse CSV"))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp get_csv_key_mapping,
    do:
      %{
        "firstname" => :first_name,
        gettext("Firstname") => :first_name,
        "lastname" => :last_name,
        gettext("Lastname") => :last_name,
        "mobile" => :mobile,
        "mobile_phone" => :mobile,
        gettext("Mobile Phone") => :mobile,
        "landline" => :landline,
        "landline phone" => :landline,
        gettext("Landline") => :landline,
        "email" => :email,
        gettext("Email") => :email,
        "tenant" => :tenant,
        gettext("Tenant") => :tenant
      }
      |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
      |> Enum.uniq()
      |> Map.new()

  defp normalize_row(%{} = row, key_mapping) do
    row
    |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
    |> Enum.filter(fn {key, _value} -> Map.has_key?(key_mapping, key) end)
    |> Enum.map(fn {key, value} -> {key_mapping[key], value} end)
    |> Map.new()
  end

  defp fetch_tenant(row, tenants) do
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

  defp normalize_key(key),
    do: key |> String.downcase() |> String.replace(~R/[^\w]+/, "", global: true)

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end

  defp get_person_name(uuid) do
    CaseContext.get_person!(uuid).first_name
  end
end
