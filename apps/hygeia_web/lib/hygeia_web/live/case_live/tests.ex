defmodule HygeiaWeb.CaseLive.Tests do
  @moduledoc false

  use HygeiaWeb, :surface_view
  alias Hygeia.CaseContext
  alias Hygeia.Repo
  alias Hygeia.CaseContext.Test
  alias Surface.Components.Form
  alias Surface.Components.LiveRedirect

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
        tests: [],
        person: [tenant: []]
      )

    socket
    |> assign(
      case: case,
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Tests")} - #{gettext("Case")}"
    )
  end

  def handle_event(
        "add_test",
        _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_add_to_params(changeset, :tests, %{uuid: Ecto.UUID.generate()})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "remove_test",
        %{"changeset-uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(changeset, :tests, %{uuid: uuid})
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
