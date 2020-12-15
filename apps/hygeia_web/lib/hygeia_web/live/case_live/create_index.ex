defmodule HygeiaWeb.CaseLive.CreateIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.CaseLive.Create

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CreateIndex.CreateSchema
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def mount(params, session, socket) do
    socket =
      if authorized?(Case, :create, get_auth(socket), tenant: :any) do
        tenants =
          Enum.filter(
            TenantContext.list_tenants(),
            &authorized?(Case, :create, get_auth(socket), tenant: &1)
          )

        supervisor_users = UserContext.list_users_with_role(:supervisor, tenants)
        tracer_users = UserContext.list_users_with_role(:tracer, tenants)
        auth_user = get_auth(socket)

        assign(socket,
          changeset:
            CreateSchema.changeset(%CreateSchema{people: []}, %{
              default_tracer_uuid: auth_user.uuid,
              default_supervisor_uuid: auth_user.uuid,
              default_country: "CH"
            }),
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          suspected_duplicate_changeset_uuid: nil,
          file: nil,
          return_to: params["return_to"],
          loading: false
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_params(params, uri, socket) do
    super(params, uri, assign(socket, suspected_duplicate_changeset_uuid: nil))
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
            |> CreateSchema.drop_empty_rows()
            |> Ecto.Changeset.fetch_field!(:people)
            |> Enum.map(&{&1, save_or_load_person_schema(&1, socket, changeset)})
            |> Enum.map(&create_case(&1, changeset))
          end)

        socket =
          put_flash(
            socket,
            :info,
            ngettext("Created Case", "Created %{n} Cases", length(cases), n: length(cases))
          )

        {:noreply, socket |> handle_save_success(CreateSchema) |> maybe_block_navigation()}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:csv_import, {:ok, data}}, socket) do
    {:noreply,
     assign(socket,
       changeset: import_into_changeset(socket.assigns.changeset, data),
       loading: false
     )}
  end

  def handle_info({:csv_import, :start}, socket) do
    {:noreply, assign(socket, loading: true)}
  end

  def handle_info({:csv_import, {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, gettext("Could not parse CSV"))
     |> assign(loading: false)}
  end

  def handle_info({:accept_duplicate, uuid, person}, socket) do
    {:noreply,
     assign(socket,
       changeset: accept_duplicate(socket.assigns.changeset, uuid, person)
     )}
  end

  def handle_info({:declined_duplicate, uuid}, socket) do
    {:noreply, assign(socket, changeset: decline_duplicate(socket.assigns.changeset, uuid))}
  end

  def handle_info({:remove_person, uuid}, socket) do
    {:noreply,
     assign(socket,
       changeset: remove_person(socket.assigns.changeset, uuid)
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp create_case({person_schema, {person, supervisor, tracer}}, global_changeset) do
    attrs = %{
      external_references: [],
      phases: [%{details: %{__type__: :index}}],
      supervisor_uuid: supervisor.uuid,
      tracer_uuid: tracer.uuid,
      clinical:
        person_schema.clinical
        |> Map.from_struct()
        |> update_in([Access.key!(:sponsor)], &Map.from_struct/1)
        |> update_in([Access.key!(:sponsor), Access.key!(:address)], &Map.from_struct/1)
        |> update_in([Access.key!(:sponsor), Access.key!(:address), Access.key!(:country)], fn
          nil -> Ecto.Changeset.get_field(global_changeset, :default_country)
          other -> other
        end)
        |> update_in([Access.key!(:reporting_unit)], &Map.from_struct/1)
        |> update_in([Access.key!(:reporting_unit), Access.key!(:address)], &Map.from_struct/1)
        |> update_in(
          [Access.key!(:reporting_unit), Access.key!(:address), Access.key!(:country)],
          fn
            nil -> Ecto.Changeset.get_field(global_changeset, :default_country)
            other -> other
          end
        )
    }

    attrs =
      if is_nil(person_schema.ism_case_id),
        do: attrs,
        else:
          Map.update!(
            attrs,
            :external_references,
            &[%{type: :ism_case, value: person_schema.ism_case_id} | &1]
          )

    attrs =
      if is_nil(person_schema.ism_report_id),
        do: attrs,
        else:
          Map.update!(
            attrs,
            :external_references,
            &[%{type: :ism_report, value: person_schema.ism_report_id} | &1]
          )

    {:ok, case} = CaseContext.create_case(person, attrs)

    case
  end

  defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
    changeset
    |> Ecto.Changeset.get_field(:people, [])
    |> case do
      [] -> push_event(socket, "unblock_navigation", %{})
      [_] -> push_event(socket, "unblock_navigation", %{})
      [_ | _] -> push_event(socket, "block_navigation", %{})
    end
  end
end
