defmodule HygeiaWeb.References do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.FormError
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop source, :map, required: true
  prop add_external_reference, :event, required: true
  prop disabled, :boolean, default: false
end
