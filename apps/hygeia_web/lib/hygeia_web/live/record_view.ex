defmodule HygeiaWeb.RecordView do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AuditContext

  prop resource, :map, required: true
  prop action, :atom, required: true

  prop wrapper_tag, :atom, default: :div

  slot default

  @impl Phoenix.LiveComponent
  def render(%{wrapper_tag: :div} = assigns) do
    trigger(assigns)

    ~F"""
    <div>
      <#slot />
    </div>
    """
  end

  def render(%{wrapper_tag: :tr} = assigns) do
    trigger(assigns)

    ~F"""
    <tr>
      <#slot />
    </tr>
    """
  end

  def render(%{wrapper_tag: :span} = assigns) do
    trigger(assigns)

    ~F"""
    <span>
      <#slot />
    </span>
    """
  end

  def render(%{wrapper_tag: :strong} = assigns) do
    trigger(assigns)

    ~F"""
    <strong>
      <#slot />
    </strong>
    """
  end

  defp trigger(assigns) do
    if Map.has_key?(assigns.__changed__, :resource) or Map.has_key?(assigns.__changed__, :action) or
         Map.has_key?(assigns.__changed__, :__context__) do
      AuditContext.log_view(
        assigns.socket.id,
        case get_auth(assigns.socket) do
          :anonymous -> assigns.__context__[{HygeiaWeb, :auth}] || :anonymous
          other -> other
        end,
        assigns.__context__[{HygeiaWeb, :ip_address}],
        assigns.__context__[{HygeiaWeb, :uri}],
        assigns.action,
        assigns.resource
      )
    end
  end
end
