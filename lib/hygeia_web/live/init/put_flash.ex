defmodule HygeiaWeb.Init.PutFlash do
  @moduledoc """
  Register Hook to allow adding flash messages on the root live view
  """

  import Phoenix.LiveView, only: [attach_hook: 4, put_flash: 3]

  @spec mount(
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket),
    do: {:cont, attach_hook(socket, __MODULE__, :handle_info, &handle_info/2)}

  defp handle_info({:put_flash, type, msg}, socket), do: {:halt, put_flash(socket, type, msg)}
  defp handle_info(_other, socket), do: {:cont, socket}
end
