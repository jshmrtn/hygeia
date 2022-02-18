# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.ImportLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Surface.Components.LiveRedirect

  data authorized_tenants, :list
  data pagination, :struct
  data import, :list

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Import, :list, get_auth(socket), tenant: :any) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "imports")

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        socket
        |> assign(
          pagination_params: pagination_params,
          filters: %{},
          page_title: gettext("Imports - Inbox"),
          authorized_tenants:
            Enum.filter(
              TenantContext.list_tenants(),
              &authorized?(Import, :list, get_auth(socket), tenant: &1)
            )
        )
        |> list_imports()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    import = ImportContext.get_import!(id)

    true = authorized?(import, :delete, get_auth(socket))

    {:ok, _} = ImportContext.delete_import(import)

    {:noreply, list_imports(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Import{}, _version}, socket) do
    {:noreply, list_imports(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_imports(socket) do
    authorized_tenant_uuids = Enum.map(socket.assigns.authorized_tenants, & &1.uuid)

    %Paginator.Page{entries: entries, metadata: metadata} =
      Repo.paginate(
        from(import in Import,
          where: import.tenant_uuid in ^authorized_tenant_uuids,
          preload: :tenant,
          order_by: [desc: import.inserted_at]
        ),
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [inserted_at: :desc])
      )

    assign(socket,
      pagination: metadata,
      imports: entries
    )
  rescue
    ArgumentError -> reraise HygeiaWeb.InvalidPaginationParamsError, __STACKTRACE__
  end
end
