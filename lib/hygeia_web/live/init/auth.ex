defmodule HygeiaWeb.Init.Auth do
  @moduledoc """
  Load Auth on mount
  """

  import Phoenix.LiveView, only: [connected?: 1, get_connect_info: 2]

  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext.User

  @spec on_mount(
          context :: atom(),
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    ip = socket |> get_ip_address() |> ip_to_string()

    attrs =
      case session["auth"] do
        nil ->
          %{}

        %User{uuid: uuid, email: email, display_name: display_name} ->
          %{
            id: uuid,
            email: email,
            username: display_name
          }

        %Person{uuid: uuid} ->
          %{
            id: uuid,
            username: "Person / #{uuid}"
          }
      end

    Sentry.Context.set_user_context(Map.merge(attrs, %{ip_address: ip}))

    Versioning.put_origin(:web)

    case session["auth"] do
      %User{} = user -> Versioning.put_originator(user)
      # TODO: Incorporate Person into Versioning
      %Person{} -> Versioning.put_originator(:noone)
      nil -> Versioning.put_originator(:noone)
    end

    {:cont, socket}
  end

  defp get_ip_address(socket) do
    if connected?(socket) and not is_nil(socket.private[:connect_info]) do
      case get_connect_info(socket, :peer_data) do
        %{address: address} -> address
        nil -> nil
      end
    end
  end

  defp ip_to_string(ip)
  defp ip_to_string(nil), do: nil
  defp ip_to_string(ip), do: ip |> :inet.ntoa() |> List.to_string()
end
