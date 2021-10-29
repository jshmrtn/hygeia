defmodule HygeiaWeb.DivisionLive.Merge do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  data delete, :map, default: nil
  data into, :map, default: nil
  data organisation, :map

  @impl Phoenix.LiveView
  def handle_params(%{"organisation_id" => organisation_id} = params, _uri, socket) do
    organisation = OrganisationContext.get_organisation!(organisation_id)

    {:noreply,
     socket
     |> assign(organisation: organisation, page_title: gettext("Merge Divisions"))
     |> load_division(:delete, params["delete"])
     |> load_division(:into, params["into"])}
  end

  @impl Phoenix.LiveView
  def handle_event("change_delete", params, socket),
    do: {:noreply, load_division(socket, :delete, params["uuid"])}

  def handle_event("change_into", params, socket),
    do: {:noreply, load_division(socket, :into, params["uuid"])}

  def handle_event("switch", _params, %{assigns: %{delete: into, into: delete}} = socket),
    do: {:noreply, assign(socket, into: into, delete: delete)}

  def handle_event("merge", %{"merge" => %{"delete" => delete, "into" => into}} = _params, socket) do
    %{assigns: %{delete: delete, into: into}} =
      socket =
      socket
      |> load_division(:delete, delete)
      |> load_division(:into, into)

    {:ok, resulting_division} = OrganisationContext.merge_divisions(delete, into)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Divisions merged successfully"))
     |> push_redirect(to: Routes.division_show_path(socket, :show, resulting_division))}
  end

  defp load_division(socket, key, uuid)
  defp load_division(socket, key, nil), do: assign(socket, key, nil)
  defp load_division(socket, key, ""), do: assign(socket, key, nil)

  defp load_division(socket, key, uuid) do
    division = OrganisationContext.get_division!(uuid)

    if authorized?(division, :update, get_auth(socket)) do
      assign(socket, key, division)
    else
      assign(socket, key, nil)
    end
  end
end
