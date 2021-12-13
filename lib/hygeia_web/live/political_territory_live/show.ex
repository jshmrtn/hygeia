defmodule HygeiaWeb.PoliticalTerritoryLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.PoliticalTerritoryContext
  alias Hygeia.PoliticalTerritoryContext.PoliticalTerritory
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    political_territory = PoliticalTerritoryContext.get_political_territory!(id)

    socket =
      if authorized?(
           political_territory,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "political_territories:#{id}")
        socket = assign(socket, page_title: "#{political_territory.name} - #{gettext("PoliticalTerritory")}")
        load_data(socket, political_territory)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %PoliticalTerritory{} = political_territory, _version}, socket) do
    {:noreply, assign(socket, :political_territory, political_territory)}
  end

  def handle_info({:deleted, %PoliticalTerritory{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.political_territory_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    political_territory = PoliticalTerritoryContext.get_political_territory!(socket.assigns.political_territory.uuid)

    {:noreply,
     socket
     |> load_data(political_territory)
     |> push_patch(to: Routes.political_territory_show_path(socket, :show, political_territory))}
  end

  def handle_event("validate", %{"political_territory" => political_territory_params}, socket) do
    {:noreply,
     assign(socket,
       changeset: %{
         PoliticalTerritoryContext.change_political_territory(socket.assigns.political_territory, political_territory_params)
         | action: :validate
       }
     )}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.political_territory, :delete, get_auth(socket))

    {:ok, _} = PoliticalTerritoryContext.delete_political_territory(socket.assigns.political_territory)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Political Territory deleted successfully"))
     |> redirect(to: Routes.political_territory_index_path(socket, :index))}
  end

  def handle_event("save", %{"political_territory" => political_territory_params}, socket) do
    true = authorized?(socket.assigns.political_territory, :update, get_auth(socket))

    socket.assigns.political_territory
    |> PoliticalTerritoryContext.update_political_territory(political_territory_params)
    |> case do
      {:ok, political_territory} ->
        {:noreply,
         socket
         |> load_data(political_territory)
         |> put_flash(:info, gettext("Political Territory updated successfully"))
         |> push_patch(to: Routes.political_territory_show_path(socket, :show, political_territory))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp load_data(socket, political_territory) do
    changeset = PoliticalTerritoryContext.change_political_territory(political_territory)

    assign(socket, political_territory: political_territory, changeset: changeset)
  end
end
