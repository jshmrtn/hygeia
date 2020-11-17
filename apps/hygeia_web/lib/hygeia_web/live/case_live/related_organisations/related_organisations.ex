defmodule HygeiaWeb.CaseLive.RelatedOrganisations do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select

  prop source, :map, required: true
  prop organisations, :list, required: true
  prop add, :event, required: true
  prop remove, :event, required: true
  prop disabled, :boolean, default: false
end
