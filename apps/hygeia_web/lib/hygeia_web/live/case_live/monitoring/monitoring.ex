defmodule HygeiaWeb.CaseLive.Monitoring do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea

  prop source, :map, required: true
  prop disabled, :boolean, default: false
end
