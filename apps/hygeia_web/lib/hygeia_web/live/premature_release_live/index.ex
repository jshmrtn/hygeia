defmodule HygeiaWeb.PrematureReleaseLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.PrematureRelease
  alias Hygeia.Repo

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid}, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [tenant: []], tenant: [])

    socket =
      if authorized?(PrematureRelease, :list, get_auth(socket), case: case) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "premature_releases")

        socket
        |> assign(
          case: case,
          page_title:
            "#{gettext("Premature Releases")} - #{case.person.first_name} #{case.person.last_name} - #{gettext("Case")}"
        )
        |> list_premature_releases()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %PrematureRelease{}, _version}, socket) do
    {:noreply, list_premature_releases(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_premature_releases(socket) do
    assign(socket,
      premature_releases: CaseContext.list_premature_releases(socket.assigns.case)
    )
  end

  defp phase_name(phase_uuid, case) do
    case.phases
    |> Enum.find(&match?(%CaseContext.Case.Phase{uuid: ^phase_uuid}, &1))
    |> case do
      nil -> gettext("Deleted")
      %CaseContext.Case.Phase{} = phase -> case_phase_type_translation(phase)
    end
  end
end
