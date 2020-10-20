defmodule HygeiaWeb.CaseLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases")

    unless is_nil(session["cldr_locale"]) do
      HygeiaWeb.Cldr.put_locale(session["cldr_locale"])
    end

    # TODO: Replace with correct Origin / Originator
    Versioning.put_origin(:web)
    Versioning.put_originator(:noone)

    {:ok, assign(socket, :cases, list_cases())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Case"))
    |> assign(:case, CaseContext.get_case!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Case"))
    |> assign(:case, %Case{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Cases"))
    |> assign(:case, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    case = CaseContext.get_case!(id)
    {:ok, _} = CaseContext.delete_case(case)

    {:noreply, assign(socket, :cases, list_cases())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Case{}, _version}, socket) do
    {:noreply, assign(socket, :cases, list_cases())}
  end

  defp list_cases do
    Repo.preload(CaseContext.list_cases(), :person)
  end
end
