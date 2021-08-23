# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.RowLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Row
  alias Hygeia.ImportContext.Row.Status
  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  data authorized_tenants, :list
  data pagination, :struct
  data import, :struct
  data rows, :list
  data status, :atom, default: :pending

  @impl Phoenix.LiveView
  def handle_params(%{"import_id" => import_id, "status" => status} = params, _uri, socket) do
    import = ImportContext.get_import!(import_id)

    socket =
      if authorized?(Row, :list, get_auth(socket), import: import) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "rows")

        timezone = context_get(socket, :timezone)

        inserted_at =
          import.inserted_at |> DateTime.shift_zone!(timezone) |> HygeiaCldr.DateTime.to_string!()

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        socket
        |> assign(
          status: String.to_existing_atom(status),
          pagination_params: pagination_params,
          list_fields: Type.list_fields(import.type),
          import: import,
          page_title:
            "#{gettext("Rows")} - #{Type.translate(import.type)} / #{inserted_at} - #{gettext("Import")} - #{gettext("Inbox")}"
        )
        |> list_rows()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Row{}, _version}, socket) do
    {:noreply, list_rows(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_rows(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      Repo.paginate(
        Ecto.assoc(
          socket.assigns.import,
          case socket.assigns.status do
            :pending -> :pending_rows
            :discarded -> :discarded_rows
            :resolved -> :resolved_rows
          end
        ),
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [uuid: :asc])
      )

    assign(socket,
      pagination: metadata,
      rows: entries
    )
  rescue
    ArgumentError -> reraise HygeiaWeb.InvalidPaginationParamsError, __STACKTRACE__
  end
end
