defmodule HygeiaWeb.ProfessionLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "professions")

    {:ok, assign(socket, :professions, list_professions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Profession"))
    |> assign(:profession, CaseContext.get_profession!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Profession"))
    |> assign(:profession, %Profession{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Professions"))
    |> assign(:profession, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    profession = CaseContext.get_profession!(id)
    {:ok, _} = CaseContext.delete_profession(profession)

    {:noreply, assign(socket, :professions, list_professions())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Profession{}}, socket) do
    {:noreply, assign(socket, :professions, list_professions())}
  end

  defp list_professions, do: CaseContext.list_professions()
end
