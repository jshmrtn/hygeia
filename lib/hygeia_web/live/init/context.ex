defmodule HygeiaWeb.Init.Context do
  @moduledoc """
  Load Context on mount
  """

  import HygeiaWeb, only: [context_assign: 3]
  import HygeiaWeb.Helpers.Auth

  import Phoenix.LiveView,
    only: [get_connect_params: 1, connected?: 1, get_connect_info: 1, attach_hook: 4]

  alias Hygeia.EctoType.LocalizedNaiveDatetime

  @default_timezone "Europe/Zurich"

  @spec mount(
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def mount(params, _session, socket) do
    socket =
      socket
      |> context_assign(:auth, get_auth(socket))
      |> context_assign(:logged_in, is_logged_in?(socket))
      |> context_assign(:browser_features, browser_features(socket))
      |> context_assign(:ip_address, get_ip_address(socket))
      |> context_assign(:uri, uri(socket))
      |> context_assign(:timezone, timezone(socket))

    socket =
      case params do
        :not_mounted_at_router -> socket
        _params -> attach_hook(socket, __MODULE__, :handle_params, &handle_params/3)
      end

    {:cont, socket}
  end

  defp timezone(socket) do
    timezone =
      with true <- connected?(socket),
           %{} <- socket.private[:connect_params],
           %{"timezone" => timezone} <- get_connect_params(socket),
           true <- Tzdata.zone_exists?(timezone) do
        timezone
      else
        false -> @default_timezone
        nil -> @default_timezone
        %{} -> @default_timezone
      end

    :ok = LocalizedNaiveDatetime.put_timezone(timezone)

    timezone
  end

  defp uri(socket) do
    case {socket.host_uri, socket.private[:connect_info][:uri]} do
      {%URI{} = uri, _connect_uri} -> URI.to_string(uri)
      {:not_mounted_at_router, %URI{} = uri} -> URI.to_string(uri)
      _other -> nil
    end
  end

  defp browser_features(socket) do
    if connected?(socket) and not is_nil(socket.private[:connect_params]) do
      get_connect_params(socket)["browser_features"]
    end
  end

  defp get_ip_address(socket) do
    if connected?(socket) and not is_nil(socket.private[:connect_info]) do
      case get_connect_info(socket) do
        %{peer_data: peer_data} ->
          peer_data.address

        _other ->
          nil
      end
    end
  end

  defp handle_params(params, uri, socket),
    do:
      {:cont,
       socket
       |> context_assign(:params, params)
       |> context_assign(:uri, uri)}
end
