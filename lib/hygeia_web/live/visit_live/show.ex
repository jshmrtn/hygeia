defmodule HygeiaWeb.VisitLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  alias Hygeia.OrganisationContext

  @impl Phoenix.LiveView
  def handle_params(%{"visit_id" => visit_id}, _uri, socket) do
    visit = OrganisationContext.get_visit!(visit_id)

    socket =
      if authorized?(
           visit,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "visit:#{visit_id}")

        load_data(socket, visit)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  def handle_event(
        "select_visit_organisation",
        params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       OrganisationContext.change_visit(
         changeset,
         %{organisation_uuid: params["uuid"]}
       )
     )}
  end

  def handle_event(
        "select_visit_division",
        params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       OrganisationContext.change_visit(
         changeset,
         %{division_uuid: params["uuid"]}
       )
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"visit" => visit_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         OrganisationContext.change_visit(socket.assigns.visit, visit_params)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  @impl Phoenix.LiveView
  def handle_event("reset", _params, %{assigns: %{visit: visit}} = socket) do
    {:noreply,
     socket
     |> load_data(visit)
     |> push_patch(
       to:
         Routes.visit_show_path(
           socket,
           :show,
           visit.uuid
         )
     )
     |> maybe_block_navigation()}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"visit" => visit_params}, socket) do
    true = authorized?(socket.assigns.visit, :update, get_auth(socket))

    socket.assigns.visit
    |> OrganisationContext.update_visit(visit_params)
    |> case do
      {:ok, visit} ->
        :ok = OrganisationContext.propagate_organisation_and_division(visit)

        {:noreply,
         socket
         |> load_data(visit)
         |> put_flash(:info, gettext("Visit updated successfully"))
         |> push_patch(to: Routes.visit_show_path(socket, :show, visit.uuid))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, %{assigns: %{visit: visit}} = socket) do
    true = authorized?(visit, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_visit(visit)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Visit deleted successfully"))
     |> redirect(to: Routes.visit_index_path(socket, :index, visit.person.uuid))}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Visit{}, _version}, socket) do
    {:noreply, load_data(socket, OrganisationContext.get_visit!(socket.assigns.visit.uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, visit) do
    visit = Repo.preload(visit, [:organisation, :division, :person])

    changeset = OrganisationContext.change_visit(visit)

    socket
    |> assign(
      visit: visit,
      person: visit.person,
      changeset: changeset,
      page_title: gettext("Visit")
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
