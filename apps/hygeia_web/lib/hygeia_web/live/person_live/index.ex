defmodule HygeiaWeb.PersonLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "people")

    super(params, session, assign(socket, :people, list_people()))
  end

  @impl Phoenix.LiveView
  def handle_event("filter", _filter, socket) do
    # TODO: implement filter
    {:noreply, socket}
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
