defmodule HygeiaWeb.TestLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    test = CaseContext.get_test!(id)

    socket =
      if authorized?(
           test,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "test:#{id}")

        load_data(socket, test)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  defp load_data(socket, test) do
    test =
      Repo.preload(test,
        mutation: [],
        case: []
      )

    changeset = CaseContext.change_test(test)

    socket
    |> assign(
      test: test,
      changeset: changeset,
      people: CaseContext.list_people(),
      page_title: gettext("Test")
    )
    |> maybe_block_navigation()
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"test" => test}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         CaseContext.change_test(%Test{}, test)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  @impl Phoenix.LiveView
  def handle_event("reset", _params, %{assigns: %{test: test}} = socket) do
    {:noreply,
     socket
     |> load_data(test)
     |> push_patch(
       to:
         Routes.test_show_path(
           socket,
           :show,
           test.case.uuid,
           test.uuid
         )
     )
     |> maybe_block_navigation()}
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
