defmodule HygeiaWeb.LiveHelpers do
  @moduledoc """
  Helpers for Live Views
  """

  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `HygeiaWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, HygeiaWeb.TenantLive.FormComponent,
        id: @tenant.uuid || :new,
        action: @live_action,
        tenant: @tenant,
        return_to: Routes.tenant_index_path(@socket, :index) %>
  """
  @spec live_modal(socket :: Phoenix.LiveView.Socket.t(), component :: atom, Keyword.t()) ::
          Phoenix.LiveView.Component.t()
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, HygeiaWeb.ModalComponent, modal_opts)
  end
end
