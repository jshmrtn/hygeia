defmodule HygeiaWeb.ProfessionLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "professions:#{id}")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:profession, CaseContext.get_profession!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Profession{} = profession}, socket) do
    {:noreply, assign(socket, :profession, profession)}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Profession{}}, socket) do
    {:noreply, redirect(socket, to: Routes.profession_index_path(socket, :index))}
  end

  defp page_title(:show), do: gettext("Show Profession")
  defp page_title(:edit), do: gettext("Edit Profession")
end
