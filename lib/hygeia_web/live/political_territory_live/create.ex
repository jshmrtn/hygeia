defmodule HygeiaWeb.PoliticalTerritoryLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.PoliticalTerritoryContext
  alias Hygeia.PoliticalTerritoryContext.PoliticalTerritory
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.TextInput

  data changeset, :map, default: nil
  data popup, :boolean, default: false

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(PoliticalTerritory, :create, get_auth(socket)) do
        assign(socket,
          changeset: PoliticalTerritoryContext.change_political_territory(%PoliticalTerritory{}),
          page_title: gettext("New Political Territory")
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"political_territory" => political_territory_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       PoliticalTerritoryContext.change_political_territory(%PoliticalTerritory{}, political_territory_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"political_territory" => political_territory_params}, socket) do
    political_territory_params
    |> PoliticalTerritoryContext.create_political_territory()
    |> case do
      {:ok, political_territory} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Political Territory created successfully"))
         |> push_redirect(to: Routes.political_territory_show_path(socket, :show, political_territory))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
