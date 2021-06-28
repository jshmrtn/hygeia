# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.ImportLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.Repo
  alias Surface.Components.Link

  data import, :struct

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    import = ImportContext.get_import!(id)

    socket =
      if authorized?(import, :details, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "imports:#{id}")

        timezone = context_get(socket, :timezone)

        inserted_at =
          import.inserted_at |> DateTime.shift_zone!(timezone) |> HygeiaCldr.DateTime.to_string!()

        socket =
          assign(socket,
            page_title:
              "#{Type.translate(import.type)} / #{inserted_at} - #{gettext("Import")} - #{gettext("Inbox")}"
          )

        load_data(socket, import)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Import{} = import, _version}, socket) do
    {:noreply, assign(socket, :import, import)}
  end

  def handle_info({:deleted, %Import{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.import_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.import, :delete, get_auth(socket))

    {:ok, _} = ImportContext.delete_import(socket.assigns.import)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Import deleted successfully"))
     |> redirect(to: Routes.import_index_path(socket, :index))}
  end

  defp load_data(socket, import), do: assign(socket, import: Repo.preload(import, tenant: []))
end
