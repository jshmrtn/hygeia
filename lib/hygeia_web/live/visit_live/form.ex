defmodule HygeiaWeb.VisitLive.Form do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias Hygeia.CaseContext.Address
  alias Hygeia.MutationContext
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.OrganisationContext.Visit.Reason
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def mount(socket), do: {:ok, socket}
end
