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
  def handle_params(%{"id" => case_id}, _uri, socket) do
    case = CaseContext.get_case!(case_id)

    socket =
      if authorized?(Visit, :list, get_auth(socket), case: case) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{case_id}")

        load_data(socket, case)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  defp load_data(socket, case) do
    case =
      Repo.preload(case, tenant: [], visits: [:organisation, :division], person: [tenant: []])

    socket
    |> assign(case: case)
    |> assign(
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Visits")} - #{gettext("Case")}"
    )
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %module{}, _version}, socket) when module in [Visit, Case] do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id} = _params, socket) do
    visit = Enum.find(socket.assigns.case.visits, &match?(%Visit{uuid: ^id}, &1))

    true = authorized?(visit, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_visit(visit)

    {:noreply,
     push_patch(socket, to: Routes.visit_index_path(socket, :index, socket.assigns.case))}
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
