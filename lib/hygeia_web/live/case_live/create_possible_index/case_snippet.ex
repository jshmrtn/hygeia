defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.RadioButton

  prop case_changeset, :map, default: nil
  prop class, :string

  slot top
end
