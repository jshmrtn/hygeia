defmodule HygeiaWeb.InfectionPlaceTypeLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.InfectionPlaceType
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(InfectionPlaceType, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "infection_place_types")

        assign(socket, :infection_place_types, list_infection_place_types())
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    infection_place_type = CaseContext.get_infection_place_type!(id)

    true = authorized?(infection_place_type, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_infection_place_type(infection_place_type)

    {:noreply, assign(socket, :infection_place_types, list_infection_place_types())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %InfectionPlaceType{}, _version}, socket) do
    {:noreply, assign(socket, :infection_place_types, list_infection_place_types())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_infection_place_types, do: CaseContext.list_infection_place_types()
end
