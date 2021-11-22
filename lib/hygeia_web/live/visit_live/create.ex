defmodule HygeiaWeb.VisitLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Visit
  alias Surface.Components.Form
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    person = CaseContext.get_person!(id)

    socket =
      if authorized?(Visit, :create, get_auth(socket), person: person) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{id}")

        load_data(socket, person)
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
         Ecto.Changeset.apply_changes(changeset),
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
     assign(socket, :changeset, %{
       OrganisationContext.change_visit(%Visit{}, visit_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"visit" => visit_params}, socket) do
    socket.assigns.person
    |> OrganisationContext.create_visit(visit_params)
    |> case do
      {:ok, visit} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Visit created successfully"))
         |> push_redirect(to: Routes.visit_index_path(socket, :index, visit.person_uuid))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp load_data(socket, person) do
    changeset = OrganisationContext.change_visit(Ecto.build_assoc(person, :visits))

    socket
    |> assign(person: person, changeset: changeset)
    |> assign(
      page_title:
        "#{person.first_name} #{person.last_name} - #{gettext("Visits")} - #{gettext("Person")}"
    )
  end
end
