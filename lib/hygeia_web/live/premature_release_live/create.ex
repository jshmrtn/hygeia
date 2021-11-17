defmodule HygeiaWeb.PrematureReleaseLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.PrematureRelease
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid, "phase_uuid" => phase_uuid}, _uri, socket) do
    case = CaseContext.get_case!(case_uuid)

    phase =
      Enum.find(case.phases, &match?(%Phase{uuid: ^phase_uuid}, &1)) || raise Ecto.NoResultsError

    socket =
      if authorized?(PrematureRelease, :create, get_auth(socket), case: case) do
        assign(socket,
          changeset: CaseContext.change_new_premature_release(case, phase),
          page_title: gettext("Premature Release"),
          case: case,
          phase: phase
        )
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url:
                Routes.premature_release_create_path(socket, :create, case_uuid, phase_uuid)
            )
        )

        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"premature_release" => premature_release_params}, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %{
         CaseContext.change_new_premature_release(
           socket.assigns.case,
           socket.assigns.phase,
           premature_release_params
         )
         | action: :validate
       }
     )}
  end

  def handle_event("save", %{"premature_release" => premature_release_params}, socket) do
    socket.assigns.case
    |> CaseContext.create_premature_release(socket.assigns.phase, premature_release_params)
    |> case do
      {:ok, _premature_release} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Premature release created successfully"))
         |> push_redirect(
           to: Routes.person_overview_index_path(socket, :index, socket.assigns.case.person_uuid)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp negative_test_too_early?(type, phase)

  defp negative_test_too_early?(:negative_test, %Phase{end: end_date}) do
    Date.compare(Date.utc_today(), Date.add(end_date, -3)) == :lt
  end

  defp negative_test_too_early?(_type, _phase), do: false
end
