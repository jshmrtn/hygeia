defmodule HygeiaWeb.CaseLive.CreateIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.CaseLive.Create

  alias Hygeia.CaseContext
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.Create.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreateIndex.CreateSchema
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select

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
            |> Ecto.Changeset.fetch_field!(:people)
            |> Enum.reject(&match?(%CreatePersonSchema{uuid: nil}, &1))
            |> Enum.map(&save_or_load_person_schema(&1, socket, changeset))
            |> Enum.map(&create_case/1)
          end)

        {:noreply,
         socket
         |> put_flash(
           :info,
           ngettext("Created Case", "Created %{n} Cases", length(cases), n: length(cases))
         )
         |> assign(
           changeset:
             changeset
             |> Ecto.Changeset.put_embed(:people, [])
             |> Map.put(:errors, [])
             |> Map.put(:valid?, true)
             |> CreateSchema.validate_changeset(),
           suspected_duplicate_changeset_uuid: nil,
           file: nil
         )
         |> maybe_block_navigation()}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:upload, data}, socket) do
    send_update(HygeiaWeb.CaseLive.CSVImport, id: "csv-import", data: data)

    {:noreply, socket}
  end

  def handle_info({:csv_import, {:ok, data}}, socket) do
    {:noreply,
     assign(socket,
       changeset: import_into_changeset(socket.assigns.changeset, data, socket.assigns.tenants)
     )}
  end

  def handle_info({:csv_import, {:error, _reason}}, socket) do
    {:noreply, put_flash(socket, :error, gettext("Could not parse CSV"))}
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

  def handle_info(_other, socket), do: {:noreply, socket}

  defp create_case({person, supervisor, tracer}) do
    {:ok, case} =
      CaseContext.create_case(person, %{
        phases: [%{details: %{__type__: :index}}],
        supervisor_uuid: supervisor.uuid,
        tracer_uuid: tracer.uuid
      })

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
