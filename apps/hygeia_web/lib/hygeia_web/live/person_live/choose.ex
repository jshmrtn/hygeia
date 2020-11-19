defmodule HygeiaWeb.PersonLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :atom

  prop change, :event

  prop disabled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(modal_open: false, query: nil)
      |> load_people

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: false)}
  end

  def handle_event("query", %{"value" => value} = _params, socket) do
    socket =
      socket
      |> assign(query: value)
      |> load_people

    {:noreply, socket}
  end

  defp load_people(socket) do
    people =
      if socket.assigns.query in [nil, ""] do
        CaseContext.list_people()
      else
        CaseContext.fulltext_person_search(socket.assigns.query)
      end

    assign(socket, people: people)
  end

  defp load_person(uuid), do: CaseContext.get_person!(uuid)
end
