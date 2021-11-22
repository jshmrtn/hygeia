defmodule HygeiaWeb.Init.DiscardEmptyHandleEvent do
  @moduledoc """
  Discard Empty Handle Event Calls

  See: https://github.com/phoenixframework/phoenix_live_view/issues/1381
  """

  import Phoenix.LiveView, only: [attach_hook: 4]

  @spec mount(
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket),
    do: {:cont, attach_hook(socket, __MODULE__, :handle_event, &handle_event/3)}

  defp handle_event(
         "validate",
         %{"_csrf_token" => _csrf_token, "_target" => ["_csrf_token"]} = params,
         socket
       )
       when map_size(params) == 2,
       do: {:halt, socket}

  defp handle_event(
         "validate",
         %{"_csrf_token" => _csrf_token, "_target" => ["_csrf_token"], "_method" => _method} =
           params,
         socket
       )
       when map_size(params) == 3,
       do: {:halt, socket}

  defp handle_event(_event, _params, socket), do: {:cont, socket}
end
