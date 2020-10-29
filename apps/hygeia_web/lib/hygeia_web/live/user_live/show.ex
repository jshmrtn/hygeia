defmodule HygeiaWeb.UserLive.Show do
  @moduledoc false
  use HygeiaWeb, :live_view

  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "users:#{id}")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, UserContext.get_user!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %User{} = user, _versionr}, socket) do
    {:noreply, assign(socket, :user, user)}
  end

  def handle_info({:deleted, %User{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.user_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp page_title(:show), do: gettext("Show User")
end
