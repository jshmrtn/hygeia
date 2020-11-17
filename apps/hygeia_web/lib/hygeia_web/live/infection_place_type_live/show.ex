defmodule HygeiaWeb.InfectionPlaceTypeLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.InfectionPlaceType
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    infection_place_type = CaseContext.get_infection_place_type!(id)

    socket =
      if authorized?(
           infection_place_type,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "infection_place_types:#{id}")

        load_data(socket, infection_place_type)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %InfectionPlaceType{} = infection_place_type}, socket) do
    {:noreply, assign(socket, :infection_place_type, infection_place_type)}
  end

  def handle_info({:deleted, %InfectionPlaceType{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.infection_place_type_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    infection_place_type =
      CaseContext.get_infection_place_type!(socket.assigns.infection_place_type.uuid)

    {:noreply,
     socket
     |> load_data(infection_place_type)
     |> push_patch(to: Routes.infection_place_type_show_path(socket, :show, infection_place_type))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"infection_place_type" => infection_place_type_params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_infection_place_type(
         socket.assigns.infection_place_type,
         infection_place_type_params
       )
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.infection_place_type, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_infection_place_type(socket.assigns.infection_place_type)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Infection Place Type deleted successfully"))
     |> redirect(to: Routes.infection_place_type_index_path(socket, :index))}
  end

  def handle_event("save", %{"infection_place_type" => infection_place_type_params}, socket) do
    true = authorized?(socket.assigns.infection_place_type, :update, get_auth(socket))

    socket.assigns.infection_place_type
    |> CaseContext.update_infection_place_type(infection_place_type_params)
    |> case do
      {:ok, infection_place_type} ->
        {:noreply,
         socket
         |> load_data(infection_place_type)
         |> put_flash(:info, gettext("Infection place type updated successfully"))
         |> push_patch(
           to: Routes.infection_place_type_show_path(socket, :show, infection_place_type)
         )}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, infection_place_type) do
    changeset = CaseContext.change_infection_place_type(infection_place_type)

    socket
    |> assign(
      infection_place_type: infection_place_type,
      changeset: changeset,
      versions: PaperTrail.get_versions(infection_place_type)
    )
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
