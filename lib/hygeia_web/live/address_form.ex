defmodule HygeiaWeb.AddressForm do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false
end
