defmodule HygeiaWeb.Init.Sentry do
  @moduledoc """
  Leave LiveView Breadcrumbs for Sentry
  """

  import Phoenix.LiveView, only: [attach_hook: 4]

  @spec mount(
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def mount(params, _session, socket) do
    :ok = Sentry.Context.set_request_context(%{url: socket.host_uri, id: socket.id})

    :ok =
      Sentry.Context.add_breadcrumb(
        category: "web.live_view.mount",
        message: inspect(params, pretty: true)
      )

    socket =
      case socket.parent_pid do
        nil -> attach_hook(socket, __MODULE__, :handle_params, &handle_params/3)
        pid when is_pid(pid) -> socket
      end

    {:cont,
     socket
     |> attach_hook(__MODULE__, :handle_event, &handle_event/3)
     |> attach_hook(__MODULE__, :handle_info, &handle_info/2)}
  end

  defp handle_event(event, params, socket) do
    :ok =
      Sentry.Context.add_breadcrumb(
        category: "web.live_view.event",
        message: "#{event} #{inspect(params, pretty: true)}",
        event: event,
        params: params
      )

    {:cont, socket}
  end

  defp handle_info(message, socket) do
    :ok =
      Sentry.Context.add_breadcrumb(
        category: "web.live_view.info",
        message: inspect(message, pretty: true)
      )

    {:cont, socket}
  end

  defp handle_params(params, uri, socket) do
    :ok = Sentry.Context.set_request_context(%{url: uri, id: socket.id})

    :ok =
      Sentry.Context.add_breadcrumb(
        category: "web.live_view.params",
        message: "#{uri} #{inspect(params, pretty: true)}",
        params: params,
        uri: uri
      )

    {:cont, socket}
  end
end
