defmodule HygeiaWeb.CaseLive.Hospitalizations do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.FormError
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select

  prop source, :map, required: true
  prop organizations, :list, required: true
  prop add_hospitalization, :event, required: true
  prop remove_hospitalization, :event, required: true
  prop disabled, :boolean, default: false
end
