defmodule HygeiaWeb.PersonLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "people")

    super(params, session, assign(socket, :people, list_people()))
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Person"))
    |> assign(:person, CaseContext.get_person!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Person"))
    |> assign(:person, %Person{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing People"))
    |> assign(:person, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    person = CaseContext.get_person!(id)
    {:ok, _} = CaseContext.delete_person(person)

    {:noreply, assign(socket, :people, list_people())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Person{}, _version}, socket) do
    {:noreply, assign(socket, :people, list_people())}
  end

  defp list_people do
    CaseContext.list_people()
  end
end
