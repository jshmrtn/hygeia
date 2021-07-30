defmodule HygeiaWeb.TestLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test
  alias Surface.Components.Form

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Test, :create, get_auth(socket)) do
        assign(socket,
          changeset: CaseContext.change_test(%Test{}, params),
          page_title: gettext("New Test")
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_id" => case_id}, _uri, socket) do
    {:noreply, assign(socket, case_id: case_id)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"test" => test}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_test(%Test{}, test)
       | action: :validate
     })}
  end

  def handle_event("save", %{"test" => test}, socket) do
    case = CaseContext.get_case!(socket.assigns.case_id)

    CaseContext.create_test(case, test)
    |> case do
      {:ok, test} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Test created successfully"))
         |> push_redirect(to: Routes.test_show_path(socket, :show, case.uuid, test))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
