defmodule HygeiaWeb.VisitLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.OrganisationContext.Visit.Reason
  alias Hygeia.Repo
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Division

  @impl Phoenix.LiveView
  def handle_params(%{"id" => person_id}, _uri, socket) do
    person = CaseContext.get_person!(person_id)

    socket =
      if authorized?(Visit, :list, get_auth(socket), person: person) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{person_id}")

        load_data(socket, person)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, tenant: [], visits: [:organisation, :division])

    changeset = CaseContext.change_person(person)

    socket
    |> assign(person: person, changeset: changeset)
    |> assign(
      page_title:
        "#{person.first_name} #{person.last_name} - #{gettext("Visits")} - #{gettext("Person")}"
    )
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %module{}, _version}, socket) when module in [Visit, Person] do
    {:noreply, load_data(socket, CaseContext.get_person!(socket.assigns.person.uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id} = _params, socket) do
    visit = Enum.find(socket.assigns.person.visits, &match?(%Visit{uuid: ^id}, &1))

    true = authorized?(visit, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_visit(visit)

    {:noreply,
     push_patch(socket, to: Routes.visit_index_path(socket, :index, socket.assigns.person))}
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
