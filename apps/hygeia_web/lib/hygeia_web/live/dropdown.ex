defmodule HygeiaWeb.Dropdown do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop class, :string, default: ""
  prop trigger_class, :string, default: ""
  prop dropdown_class, :string, default: ""

  data dropdown_open, :boolean, default: false

  slot trigger, required: true
  slot default, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div
      tabindex="-1"
      id={{ @id <> "_dropdown" }}
      phx-hook="Dropdown"
      class={{
        "dropdown",
        @class,
        show: @dropdown_open
      }}
    >
      <div class={{ @trigger_class }} :on-click="toggle_dropdown">
        <slot name="trigger" />
      </div>

      <div class={{
        "dropdown-menu",
        @dropdown_class,
        show: @dropdown_open
      }}>
        <slot />
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: !socket.assigns.dropdown_open)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: false)}
  end
end
