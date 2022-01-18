defmodule HygeiaWeb.PersonLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias HygeiaWeb.DateInput

  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  alias Hygeia.CaseContext.Person.VaccinationShot.VaccineType

  prop disabled, :boolean, default: false
  prop show_buttons, :boolean, default: true
  prop changeset, :map
  prop person, :map
  prop subject, :any, default: nil

  prop add_event, :event
  prop remove_event, :event
end
