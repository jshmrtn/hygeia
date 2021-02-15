defmodule HygeiaWeb.DivisionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    division = OrganisationContext.get_division!(id)

    socket =
      if authorized?(
           division,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "divisions:#{id}")

        load_data(socket, division)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Division{} = division, _version}, socket) do
    {:noreply, load_data(socket, division)}
  end

  def handle_info({:deleted, %Division{}, _version}, socket) do
    {:noreply,
     redirect(socket,
       to: Routes.division_index_path(socket, :index, socket.assigns.division.organisation)
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> load_data(socket.assigns.division)
     |> push_patch(to: Routes.division_show_path(socket, :show, socket.assings.division))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"division" => division_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         OrganisationContext.change_division(socket.assigns.division, division_params)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.division, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_division(socket.assigns.division)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Division deleted successfully"))
     |> redirect(to: Routes.organisation_index_path(socket, :index))}
  end

  def handle_event("save", %{"division" => division_params}, socket) do
    true = authorized?(socket.assigns.division, :update, get_auth(socket))

    socket.assigns.division
    |> OrganisationContext.update_division(division_params)
    |> case do
      {:ok, division} ->
        {:noreply,
         socket
         |> load_data(division)
         |> put_flash(:info, gettext("Division updated successfully"))
         |> push_patch(to: Routes.division_show_path(socket, :show, division))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, division) do
    division = Repo.preload(division, organisation: [])
    changeset = OrganisationContext.change_division(division)

    socket
    |> assign(
      division: division,
      changeset: changeset,
      page_title:
        "#{division.title} - #{gettext("Division")} - #{division.organisation.name} - #{
          gettext("Organisation")
        }"
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
