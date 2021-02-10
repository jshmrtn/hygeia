defmodule HygeiaWeb.OrganisationLive.Merge do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  data delete, :map, default: nil
  data into, :map, default: nil

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> load_organisation(:delete, params["delete"])
     |> load_organisation(:into, params["into"])}
  end

  @impl Phoenix.LiveView
  def handle_event("change_delete", params, socket),
    do: {:noreply, load_organisation(socket, :delete, params["uuid"])}

  def handle_event("change_into", params, socket),
    do: {:noreply, load_organisation(socket, :into, params["uuid"])}

  def handle_event("switch", _params, %{assigns: %{delete: into, into: delete}} = socket),
    do: {:noreply, assign(socket, into: into, delete: delete)}

  def handle_event("merge", %{"merge" => %{"delete" => delete, "into" => into}} = _params, socket) do
    %{assigns: %{delete: delete, into: into}} =
      socket =
      socket
      |> load_organisation(:delete, delete)
      |> load_organisation(:into, into)

    {:ok, resulting_organisation} = OrganisationContext.merge_organisations(delete, into)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Organisations merged successfully"))
     |> push_redirect(to: Routes.organisation_show_path(socket, :show, resulting_organisation))}
  end

  defp load_organisation(socket, key, uuid)
  defp load_organisation(socket, key, nil), do: assign(socket, key, nil)
  defp load_organisation(socket, key, ""), do: assign(socket, key, nil)

  defp load_organisation(socket, key, uuid) do
    organisation = OrganisationContext.get_organisation!(uuid)

    if authorized?(organisation, :update, get_auth(socket)) do
      assign(socket, key, organisation)
    else
      assign(socket, key, nil)
    end
  end
end
