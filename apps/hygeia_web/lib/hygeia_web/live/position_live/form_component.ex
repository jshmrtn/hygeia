defmodule HygeiaWeb.PositionLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :live_component

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext

  @impl Phoenix.LiveComponent
  def update(%{position: position} = assigns, socket) do
    changeset = OrganisationContext.change_position(position)

    people = CaseContext.list_people()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:people, people)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"position" => position_params}, socket) do
    changeset =
      socket.assigns.position
      |> OrganisationContext.change_position(position_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"position" => position_params}, socket) do
    save_position(socket, socket.assigns.action, position_params)
  end

  defp save_position(socket, :position_edit, position_params) do
    case OrganisationContext.update_position(socket.assigns.position, position_params) do
      {:ok, _position} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Position updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_position(socket, :position_new, position_params) do
    case OrganisationContext.create_position(position_params) do
      {:ok, _position} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Position created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
