defmodule HygeiaWeb.CaseLive.AddressInput do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Address

  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :atom

  prop disabled, :boolean, default: false

  slot default, args: [:address]

  data modal_open, :boolean, default: false

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: false)}
  end

  defp merged_address(form) do
    Ecto.Changeset.apply_changes(form.source)
  end
end
