defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Summary do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  alias Hygeia.CaseContext.Case.Status

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAdministration
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineContactMethods

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true
end
