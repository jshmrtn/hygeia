defmodule HygeiaWeb.CaseLive.Tests do
  @moduledoc false

  use HygeiaWeb, :surface_view
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result
  alias Hygeia.Repo
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => case_id}, _uri, socket) do
    case = CaseContext.get_case!(case_id)

    socket =
      if authorized?(
           case,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
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
      Repo.preload(
        case,
        tests: [mutation: []],
        person: [tenant: []]
      )

    assign(
      socket,
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

    true = authorized?(test, :delete, get_auth(socket), %{case: test.case})

    {:ok, _} = CaseContext.delete_test(test)

    {:noreply, socket}
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
