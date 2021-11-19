defmodule HygeiaWeb.VisitLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Changeset

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.EctoType.NOGA
  alias Hygeia.Helpers.Empty
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.OrganisationContext.Visit.Reason
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    person = CaseContext.get_person!(id)

    socket =
      if authorized?(Visit, :list, get_auth(socket), person) do
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
        %{"subject" => visit_uuid} = params,
        %{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_person(
         person,
         changeset_update_params_by_id(
           changeset,
           :visits,
           %{uuid: visit_uuid},
           &Map.put(&1, "organisation_uuid", params["uuid"])
         )
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "select_visit_division",
        %{"subject" => visit_uuid} = params,
        %{assigns: %{changeset: changeset, person: person}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_person(
         person,
         changeset_update_params_by_id(
           changeset,
           :visits,
           %{uuid: visit_uuid},
           &Map.put(&1, "division_uuid", params["uuid"])
         )
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    true = authorized?(socket.assigns.person, :update, get_auth(socket))

    person_params = Map.put_new(person_params, "visits", [])

    socket.assigns.person
    |> CaseContext.update_person(person_params)
    |> case do
      {:ok, person} ->
        {:noreply,
         socket
         |> load_data(person)
         |> put_flash(:info, gettext("Visits updated successfully"))
         |> push_patch(to: Routes.person_visits_path(socket, :index, person))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, tenant: [], visits: [])

    changeset = OrganisationContext.change_visit(Ecto.build_assoc(person, :visits))

    socket
    |> assign(person: person, changeset: changeset)
    |> assign(
      page_title: "#{person.first_name} #{person.last_name} - #{gettext("Visits")} - #{gettext("Person")}"
    )
    |> maybe_block_navigation()
  end

  defp load_people_by_id(ids) do
    CaseContext.list_people_by_ids(ids)
  end

  defp load_organisation(id), do: OrganisationContext.get_organisation!(id)

  defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
    if Empty.is_empty?(changeset, [:suspected_duplicates_uuid]) do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
