defmodule HygeiaWeb.TestLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Test
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(%{"id" => id} = params, _session, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(Test, :create, get_auth(socket), %{case: case}) do
        socket
        |> load_data(case)
        |> assign(
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
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign(socket, case_id: id)}
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

    case
    |> CaseContext.create_test(test)
    |> case do
      {:ok, test} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Test created successfully"))
         |> push_redirect(to: Routes.test_show_path(socket, :show, test))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp load_data(socket, case) do
    case =
      Repo.preload(case,
        person: []
      )

    assign(socket, case: case)
  end
end
