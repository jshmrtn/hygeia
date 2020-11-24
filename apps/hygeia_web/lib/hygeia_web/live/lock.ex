defmodule HygeiaWeb.Lock do
  @moduledoc """
  Lock Resource for Edit until a lock can be acquired
  """

  use HygeiaWeb, :surface_live_component

  prop resource, :any, required: true
  prop lock, :boolean, default: true

  slot default, required: true

  data lock_acquired, :boolean, default: false
  data lock_task, :module, default: nil

  @impl Phoenix.LiveComponent
  def update(%{__lock_acquired__: true} = _assigns, socket) do
    {:ok, assign(socket, lock_acquired: true)}
  end

  case Mix.env() do
    :test ->
      def update(assigns, socket) do
        {:ok,
         socket
         |> assign(assigns)
         |> assign(lock_acquired: true)}
      end

    _env ->
      def update(assigns, socket) do
        socket =
          socket
          |> assign(assigns)
          |> assign(lock_acquired: false)

        socket =
          case socket.assigns.lock_task do
            nil ->
              socket

            task ->
              Task.shutdown(task)

              assign(socket, lock_task: nil)
          end

        pid = self()

        socket =
          cond do
            !socket.connected? ->
              # Not connected can not handle locks, therefore we're just giving it access
              assign(socket, lock_acquired: true)

            !socket.assigns.lock ->
              socket

            socket.assigns.lock ->
              assign(socket,
                lock_task:
                  Task.async(fn ->
                    if :global.set_lock({socket.assigns.resource, socket.root_pid}) do
                      # TODO: Replace with solution of https://github.com/phoenixframework/phoenix_live_view/issues/1244
                      send(
                        pid,
                        {:phoenix, :send_update,
                         {__MODULE__, socket.assigns.id,
                          %{
                            __lock_acquired__: true
                          }}}
                      )

                      # Max Lock Time
                      Process.sleep(:timer.minutes(15))
                    end
                  end)
              )
          end

        {:ok, socket}
      end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <slot
        :if={{ not(@lock) or @lock_acquired }}
      />
      <div
        :if={{ @lock and not(@lock_acquired) }}
        class="alert alert-info"
      >
        <p>{{ gettext("Someone else is currently editing this resource. Wait until they finished their work.")}}</p>

        <div class="spinner-border" role="status">
          <span class="sr-only">{{ gettext("Acquiring Lock...") }}</span>
        </div>
      </div>
    </div>
    """
  end
end
