defmodule HygeiaWeb.TestLive.Form do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result
  alias Hygeia.MutationContext
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false

  data mutations, :list, default: []

  @impl Phoenix.LiveComponent
  def mount(socket), do: {:ok, assign(socket, :mutations, MutationContext.list_mutations())}
end
