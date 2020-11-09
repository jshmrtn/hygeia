defmodule HygeiaWeb.CaseLive.Monitoring do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.FormError
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea

  prop source, :map, required: true
  prop disabled, :boolean, default: false
end
