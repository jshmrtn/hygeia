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

  def update(
        %{resource: new_resource} = assigns,
        %Phoenix.LiveView.Socket{assigns: %{resource: old_resource}} = socket
      )
      when new_resource != old_resource do
    {:ok, reset_lock(socket, assigns)}
  end

  def update(
        %{lock: new_lock} = assigns,
        %Phoenix.LiveView.Socket{assigns: %{lock: old_lock}} = socket
      )
      when new_lock != old_lock do
    {:ok, reset_lock(socket, assigns)}
  end

  def update(
        %{lock: true} = assigns,
        %Phoenix.LiveView.Socket{assigns: %{lock_acquired: false, lock_task: nil}} = socket
      ) do
    {:ok, reset_lock(socket, assigns)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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

  case Mix.env() do
    :test ->
      defp reset_lock(socket, assigns) do
        socket
        |> assign(assigns)
        |> assign(lock_acquired: true)
      end

    _env ->
      defp reset_lock(socket, assigns) do
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
                    send_update(pid, __MODULE__, id: socket.assigns.id, __lock_acquired__: true)

                    # Max Lock Time
                    Process.sleep(:timer.minutes(15))
                  end
                end)
            )
        end
      end
  end
end
