defmodule HygeiaWeb.CaseLive.TransmissionTable do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type, as: PossibleIndexType
  alias Hygeia.CaseContext.Transmission
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  prop transmissions, :list, required: true
  prop show_recipient, :boolean, default: true
  prop show_propagator, :boolean, default: true
  prop id_prefix, :string, default: "transmission"

  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop timezone, :string, from_context: {HygeiaWeb, :timezone}

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, suspected_duplicate_changeset_uuid: nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete", %{"id" => id} = _params, socket) do
    transmission = Enum.find(socket.assigns.transmissions, &match?(%Transmission{uuid: ^id}, &1))

    true = authorized?(transmission, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_transmission(transmission)

    send(self(), :reload)

    {:noreply, socket}
  end
end
