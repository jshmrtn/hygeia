defmodule HygeiaWeb.PositionLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_component

  alias Hygeia.OrganisationContext
  alias Hygeia.Repo

  @impl Phoenix.LiveComponent
  def update(%{organisation: organisation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :organisation,
       Repo.preload(organisation, positions: [person: []])
     )
     |> apply_action(assigns.live_action, assigns.params)}
  end

  defp apply_action(socket, :position_edit, %{"position_id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Position"))
    |> assign(:position, OrganisationContext.get_position!(id))
  end

  defp apply_action(socket, :position_new, _params) do
    socket
    |> assign(:page_title, gettext("New Position"))
    |> assign(:position, Ecto.build_assoc(socket.assigns.organisation, :positions))
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> assign(:page_title, gettext("Listing Positions"))
    |> assign(:position, nil)
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete", %{"id" => id}, socket) do
    position = OrganisationContext.get_position!(id)
    {:ok, _} = OrganisationContext.delete_position(position)

    organisation =
      socket.assigns.organisation.uuid
      |> OrganisationContext.get_organisation!()
      |> Repo.preload(positions: [person: []])

    {:noreply, assign(socket, :organisation, organisation)}
  end
end
