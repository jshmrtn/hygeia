defmodule HygeiaWeb.CaseLive.Monitoring do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias HygeiaWeb.PolyfilledDateInput, as: DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea

  prop source, :map, required: true
  prop disabled, :boolean, default: false
end
