defmodule HygeiaWeb.CaseLive.Tests do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop source, :map, required: true
  prop add_test, :event, required: true
  prop remove_test, :event, required: true
  prop disabled, :boolean, default: false
end
