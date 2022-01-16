defmodule HygeiaWeb.PersonLive.CreateForm do
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
  alias Surface.Components.Link

  prop changeset, :map, required: true
  prop disabled, :boolean, default: false
  prop tenants, :list, required: true
  prop form_id, :string, default: "create-person-form"
  prop subject, :any, default: nil

  prop change, :event
  prop submit, :event
  prop add_contact_method, :event
  prop remove_contact_method, :event
  prop target, :any

  slot footer, required: false
  slot address_actions, required: false
end
