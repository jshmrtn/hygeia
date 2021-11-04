defmodule HygeiaWeb.RecordView do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AuditContext

  prop resource, :map, required: true
  prop action, :atom, required: true

  prop wrapper_tag, :atom, default: :div

  slot default

  @impl Phoenix.LiveComponent
  for wrapper_tag <- [:div, :tr, :span, :strong] do
    def render(%{wrapper_tag: unquote(wrapper_tag)} = assigns) do
      ~F"""
      <Context get={HygeiaWeb, auth: auth, ip_address: ip_address, uri: uri}>
        {raw("<#{@wrapper_tag}>")}
        {trigger(assigns, %{auth: auth, ip_address: ip_address, uri: uri})}
        <#slot />
        {raw("</#{@wrapper_tag}>")}
      </Context>
      """
    end
  end

  defp trigger(assigns, %{auth: auth, ip_address: ip_address, uri: uri}) do
    if Enum.any?([:resource, :action, :__context__], &changed?(assigns, &1)) do
      AuditContext.log_view(
        assigns.socket.id,
        case get_auth(assigns.socket) do
          :anonymous -> auth || :anonymous
          other -> other
        end,
        ip_address,
        uri,
        assigns.action,
        assigns.resource
      )
    end

    nil
  end
end
