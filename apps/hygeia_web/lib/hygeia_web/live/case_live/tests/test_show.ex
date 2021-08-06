defmodule HygeiaWeb.CaseLive.TestShow do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"test_id" => test_id}, _uri, socket) do
    test = CaseContext.get_test!(test_id)

    socket =
      if authorized?(
           test,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "test:#{test_id}")

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
        case: [person: []]
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
         Routes.case_test_show_path(
           socket,
           :show,
           test.case.uuid,
           test.uuid
         )
     )
     |> maybe_block_navigation()}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"test" => test_params}, socket) do
    socket.assigns.test
    |> CaseContext.update_test(test_params)
    |> case do
      {:ok, test} ->
        {:noreply,
         socket
         |> load_data(test)
         |> put_flash(:info, gettext("Test updated successfully"))
         |> push_patch(to: Routes.case_test_show_path(socket, :show, test.case.uuid, test.uuid))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Test{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_test!(socket.assigns.test.uuid))}
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
