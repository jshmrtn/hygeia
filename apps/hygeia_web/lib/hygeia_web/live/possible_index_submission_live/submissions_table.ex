defmodule HygeiaWeb.PossibleIndexSubmissionLive.SubmissionsTable do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true
  prop return_url, :string, default: nil
end
