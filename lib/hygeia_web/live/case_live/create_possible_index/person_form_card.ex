defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.PersonFormCard do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Hygeia.CaseContext.Person

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  prop index, :integer, required: true
  prop changeset, :any, default: nil
  prop class, :string
  prop tenants, :list, required: true
  prop disabled, :boolean, default: false

  prop update, :event, required: true
  prop add_contact_method, :event, required: true
  prop remove_contact_method, :event, required: true

  slot address_title_right
  slot bottom
  slot error
end
