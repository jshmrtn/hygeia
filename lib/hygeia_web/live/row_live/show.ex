# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.RowLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Row
  alias Hygeia.Repo
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  require Logger

  data row, :struct

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    row =
      id
      |> ImportContext.get_row!()
      |> Repo.preload(import: [])

    socket =
      if authorized?(row, :details, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "rows:#{id}")

        timezone = Context.get(socket, HygeiaWeb, :timezone)

        inserted_at =
          row.import.inserted_at
          |> DateTime.shift_zone!(timezone)
          |> HygeiaCldr.DateTime.to_string!()

        socket =
          assign(socket,
            page_title:
              "Show - #{row.uuid} - #{Type.translate(row.import.type)} / #{inserted_at} - #{gettext("Import")} - #{gettext("Inbox")}"
          )

        load_data(socket, row)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("discard", _params, socket) do
    {:ok, row} = ImportContext.update_row(socket.assigns.row, %{status: :discarded})

    {:noreply, load_data(socket, row)}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Row{} = row, _version}, socket) do
    {:noreply, load_data(socket, row)}
  end

  def handle_info({:deleted, %Row{import_uuid: import_uuid}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.import_show_path(socket, :show, import_uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, row) do
    assign(socket,
      row:
        Repo.preload(row,
          imports: [tenant: []],
          tenant: [],
          case: [tenant: [], person: [tenant: []]]
        )
    )
  end
end
