defmodule HygeiaWeb.CaseLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.Repo
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :atom

  prop change, :event

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(modal_open: false, query: nil)
      |> load_cases

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
      |> load_cases

    {:noreply, socket}
  end

  defp load_cases(socket) do
    cases =
      if socket.assigns.query in [nil, ""] do
        CaseContext.list_cases()
      else
        CaseContext.fulltext_case_search(socket.assigns.query)
      end

    assign(socket, cases: Repo.preload(cases, person: []))
  end

  defp load_case(uuid), do: uuid |> CaseContext.get_case!() |> Repo.preload(person: [])
end
