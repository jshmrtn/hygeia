defmodule HygeiaWeb.RecordView do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AuditContext

  prop resource, :map, required: true
  prop action, :atom, required: true

  prop wrapper_tag, :atom, default: :div

  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop ip_address, :tuple, from_context: {HygeiaWeb, :ip_address}
  prop uri, :string, from_context: {HygeiaWeb, :uri}

  slot default

  @impl Phoenix.LiveComponent
  def render(assigns) do
    trigger(assigns)

    render_contents(assigns)
  end

  defp render_contents(%{wrapper_tag: :div} = assigns) do
    ~F"""
    <div><#slot /></div>
    """
  end

  defp render_contents(%{wrapper_tag: :tr} = assigns) do
    ~F"""
    <tr><#slot /></tr>
    """
  end

  defp render_contents(%{wrapper_tag: :span} = assigns) do
    ~F"""
    <span><#slot /></span>
    """
  end

  defp render_contents(%{wrapper_tag: :strong} = assigns) do
    ~F"""
    <strong><#slot /></strong>
    """
  end

  defp trigger(assigns) do
    if Enum.any?([:resource, :action, :__context__], &changed?(assigns, &1)) do
      AuditContext.log_view(
        assigns.socket.id,
        case get_auth(assigns.socket) do
          :anonymous -> assigns.auth || :anonymous
          other -> other
        end,
        assigns.ip_address,
        assigns.uri,
        assigns.action,
        assigns.resource
      )
    end

    nil
  end
end
