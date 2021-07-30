defmodule HygeiaWeb.CaseLive.Tests do
  @moduledoc false

  use HygeiaWeb, :surface_view
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.CaseContext.Test
  alias Surface.Components.Form
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect
  alias Surface.Components.LivePatch
  alias Hygeia.CaseContext.Test.Kind
  Hygeia.CaseContext.Test.Result

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(
           case,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

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
      Repo.preload(
        case,
        tests: [mutation: []],
        person: [tenant: []]
      )

    socket
    |> assign(
      case: case,
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Tests")} - #{gettext("Case")}"
    )
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Test{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id} = _params, socket) do
    test = Enum.find(socket.assigns.case.tests, &match?(%Test{uuid: ^id}, &1))

    true = authorized?(test, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_test(test)

    {:noreply, socket}
  end
end
