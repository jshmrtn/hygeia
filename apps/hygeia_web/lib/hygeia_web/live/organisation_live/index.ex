defmodule HygeiaWeb.OrganisationLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Organisation, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "organisations")

        assign(socket, :organisations, list_organisations())
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    organisation = OrganisationContext.get_organisation!(id)

    true = authorized?(organisation, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_organisation(organisation)

    {:noreply, assign(socket, :organisations, list_organisations())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Organisation{}, _version}, socket) do
    {:noreply, assign(socket, :organisations, list_organisations())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_organisations, do: OrganisationContext.list_organisations()
end
