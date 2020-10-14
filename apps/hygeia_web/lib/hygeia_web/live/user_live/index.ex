defmodule HygeiaWeb.UserLive.Index do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "users")

    {:ok, assign(socket, :users, list_users())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing User"))
    |> assign(:user, nil)
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %User{}}, socket) do
    {:noreply, assign(socket, :users, list_users())}
  end

  defp list_users, do: UserContext.list_users()
end
