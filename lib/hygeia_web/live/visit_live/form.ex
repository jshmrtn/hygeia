defmodule HygeiaWeb.VisitLive.Form do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias Hygeia.CaseContext.Address
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Visit.Reason
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false
  prop show_buttons, :boolean, default: true

  prop select_organisation, :event
  prop select_division, :event

  @impl Phoenix.LiveComponent
  def mount(socket), do: {:ok, socket}
end
