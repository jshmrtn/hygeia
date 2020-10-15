defmodule HygeiaWeb.PersonLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Versioning

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # TODO: Replace with correct Origin / Originator
    Versioning.put_origin(:web)
    Versioning.put_originator(:noone)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{id}")

    person = CaseContext.get_person!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:person, person)
     |> assign(:versions, PaperTrail.get_versions(person))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Person{} = person, _version}, socket) do
    {:noreply, assign(socket, :person, person)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Person{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.person_index_path(socket, :index))}
  end

  defp page_title(:show), do: gettext("Show Person")
  defp page_title(:edit), do: gettext("Edit Person")
end
