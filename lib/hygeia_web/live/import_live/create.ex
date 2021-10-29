defmodule HygeiaWeb.ImportLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CaseLiveHelper
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.LiveFileInput

  data changeset, :map, default: nil

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     if authorized?(Import, :create, get_auth(socket), tenant: :any) do
       tenants =
         Enum.filter(
           TenantContext.list_tenants(),
           &authorized?(Import, :create, get_auth(socket), tenant: &1)
         )

       supervisor_users = UserContext.list_users_with_role(:supervisor, tenants)
       tracer_users = UserContext.list_users_with_role(:tracer, tenants)

       socket
       |> assign(
         changeset: ImportContext.change_import(%Import{}),
         page_title: gettext("New Import"),
         tenants: tenants,
         supervisor_users: supervisor_users,
         tracer_users: tracer_users
       )
       |> allow_upload(:file,
         accept: ~w(.csv .xlsx .json),
         max_entries: 1,
         max_file_size: 1_000_000
       )
     else
       socket
       |> push_redirect(to: Routes.home_index_path(socket, :index))
       |> put_flash(:error, gettext("You are not authorized to do this action."))
     end}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"import" => import_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       ImportContext.change_import(%Import{}, import_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"import" => %{"tenant_uuid" => tenant_uuid} = import_params}, socket) do
    tenant = Enum.find(socket.assigns.tenants, &match?(%Tenant{uuid: ^tenant_uuid}, &1))

    [response] =
      consume_uploaded_entries(socket, :file, fn %{path: path},
                                                 %{client_type: mime, client_name: client_name} ->
        tenant
        |> ImportContext.create_import(
          mime,
          path,
          Map.put(import_params, "filename", client_name)
        )
        |> case do
          {:ok, import} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Import created successfully"))
             |> push_redirect(to: Routes.import_show_path(socket, :show, import))}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
      end)

    response
  end
end
