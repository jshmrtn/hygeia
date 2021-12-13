defmodule HygeiaWeb.PoliticalTerritoryLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.PoliticalTerritoryContext
  alias Hygeia.PoliticalTerritoryContext.PoliticalTerritory
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(PoliticalTerritory, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "political_territories")

        assign(socket,
          page_title: gettext("Political Territories"),
          political_territories: PoliticalTerritoryContext.list_political_territories()
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    political_territory = PoliticalTerritoryContext.get_political_territory!(id)

    true = authorized?(political_territory, :delete, get_auth(socket))

    {:ok, _} = PoliticalTerritoryContext.delete_political_territory(political_territory)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Political Territory deleted successfully"))
     |> assign(political_territories: PoliticalTerritoryContext.list_political_territories())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %PoliticalTerritory{}, _version}, socket) do
    {:noreply, assign(socket, political_territories: PoliticalTerritoryContext.list_political_territories())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
