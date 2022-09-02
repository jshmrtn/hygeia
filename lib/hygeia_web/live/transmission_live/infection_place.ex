defmodule HygeiaWeb.TransmissionLive.InfectionPlace do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field

  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false
  prop form, :form, from_context: {Form, :form}
end
