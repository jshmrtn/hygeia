defmodule HygeiaWeb.RecordView do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.Helpers.ViewerLogging

  prop resource, :map, required: true
  prop action, :atom, required: true

  prop wrapper_tag, :atom, default: :div

  slot default

  @impl Phoenix.LiveComponent
  def render(%{wrapper_tag: :div} = assigns) do
    trigger(assigns)

    ~H"""
    <div>
      <slot />
    </div>
    """
  end

  def render(%{wrapper_tag: :tr} = assigns) do
    trigger(assigns)

    ~H"""
    <tr>
      <slot />
    </tr>
    """
  end

  def render(%{wrapper_tag: :span} = assigns) do
    trigger(assigns)

    ~H"""
    <span>
      <slot />
    </span>
    """
  end

  def render(%{wrapper_tag: :strong} = assigns) do
    trigger(assigns)

    ~H"""
    <strong>
      <slot />
    </strong>
    """
  end

  defp trigger(assigns) do
    if Map.has_key?(assigns.__changed__, :resource) or Map.has_key?(assigns.__changed__, :action) or
         Map.has_key?(assigns.__changed__, :__context__) do
      ViewerLogging.log_viewer(
        assigns.socket.id,
        assigns.__context__[{HygeiaWeb, :auth}],
        assigns.__context__[{HygeiaWeb, :ip_address}],
        assigns.__context__[{HygeiaWeb, :uri}],
        assigns.action,
        assigns.resource
      )
    end
  end
end
