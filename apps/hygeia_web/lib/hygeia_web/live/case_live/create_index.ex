defmodule HygeiaWeb.CaseLive.CreateIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.CaseLive.Create

  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreateIndex.CreateSchema
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def mount(params, _session, socket) do
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
              default_supervisor_uuid: auth_user.uuid
            }),
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          suspected_duplicate_changeset_uuid: nil,
          file: nil,
          return_to: params["return_to"],
          loading: false,
          page_title: "#{gettext("Create Index Cases")} - #{gettext("Cases")}"
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
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
        global = Ecto.Changeset.apply_changes(changeset)

        {:ok, cases} =
          Repo.transaction(fn ->
            changeset
            |> CreateSchema.drop_empty_rows()
            |> Ecto.Changeset.fetch_field!(:people)
            |> Enum.map(&{&1, CreatePersonSchema.upsert(&1, socket, global)})
            |> Enum.map(&CreateSchema.upsert_case(&1, global))
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
     socket
     |> assign(
       changeset: import_into_changeset(socket.assigns.changeset, data, CreateSchema),
       loading: false
     )
     |> maybe_block_navigation()}
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

  def handle_info({:accept_duplicate, uuid, case_or_person}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: accept_duplicate(socket.assigns.changeset, uuid, case_or_person, CreateSchema)
     )
     |> maybe_block_navigation()}
  end

  def handle_info({:declined_duplicate, uuid}, socket) do
    {:noreply,
     assign(socket, changeset: decline_duplicate(socket.assigns.changeset, uuid, CreateSchema))}
  end

  def handle_info({:remove_person, uuid}, socket) do
    {:noreply,
     socket
     |> assign(changeset: remove_person(socket.assigns.changeset, uuid, CreateSchema))
     |> maybe_block_navigation()}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

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
