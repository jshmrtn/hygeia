defmodule HygeiaWeb.Init.Context do
  @moduledoc """
  Load Context on mount
  """

  import HygeiaWeb.Helpers.Auth

  import Phoenix.LiveView,
    only: [get_connect_params: 1, connected?: 1, get_connect_info: 2, attach_hook: 4]

  import Phoenix.Component, only: [assign: 2]

  alias Hygeia.EctoType.LocalizedNaiveDatetime
  alias Surface.Components.Context

  @default_timezone "Europe/Zurich"

  @spec on_mount(
          context :: atom(),
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, params, _session, socket) do
    :ok =
      Sentry.Context.set_extra_context(%{
        timezone: timezone(socket),
        ip_address: socket |> get_ip_address() |> ip_to_string()
      })

    :ok =
      Sentry.Context.set_request_context(%{
        env: %{
          "REMOTE_ADDR" => socket |> get_ip_address() |> ip_to_string(),
          "REMOTE_PORT" => get_remote_port(socket)
        }
      })

    context = [
      auth: get_auth(socket),
      logged_in: is_logged_in?(socket),
      browser_features: browser_features(socket),
      ip_address: get_ip_address(socket),
      uri: uri(socket),
      timezone: timezone(socket)
    ]

    socket =
      socket
      |> assign(context)
      |> Context.put(HygeiaWeb, context)

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
    case {socket.host_uri, get_uri(socket)} do
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
      case get_connect_info(socket, :peer_data) do
        %{address: address} -> address
        nil -> nil
      end
    end
  end

  defp get_uri(socket) do
    if connected?(socket) and not is_nil(socket.private[:connect_info]) do
      get_connect_info(socket, :uri)
    end
  end

  defp ip_to_string(ip)
  defp ip_to_string(nil), do: nil
  defp ip_to_string(ip), do: ip |> :inet.ntoa() |> List.to_string()

  defp get_remote_port(socket) do
    if connected?(socket) and not is_nil(socket.private[:connect_info]) do
      case get_connect_info(socket, :peer_data) do
        %{port: port} -> port
        nil -> nil
      end
    end
  end

  defp handle_params(params, uri, socket),
    do:
      {:cont,
       socket
       |> assign(params: params, uri: uri)
       |> Context.put(HygeiaWeb, params: params, uri: uri)}
end
