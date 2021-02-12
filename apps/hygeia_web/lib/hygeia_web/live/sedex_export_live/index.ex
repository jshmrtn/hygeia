defmodule HygeiaWeb.SedexExportLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.SedexExport
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(%{"tenant_id" => tenant_uuid} = params, _session, socket) do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    socket =
      if authorized?(SedexExport, :list, get_auth(socket), tenant: tenant) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "sedex_exports")

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        socket
        |> assign(
          pagination_params: pagination_params,
          tenant: tenant,
          page_title: "#{tenant.name} - #{gettext("Sedex Exports")} - #{gettext("Tenant")}"
        )
        |> list_sedex_exports
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %SedexExport{}, _version}, socket) do
    {:noreply, list_sedex_exports(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_sedex_exports(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.tenant
      |> TenantContext.list_sedex_exports_query()
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [name: :asc])
      )

    assign(socket,
      pagination: metadata,
      sedex_exports: entries
    )
  end
end
