defmodule HygeiaWeb.PossibleIndexSubmissionLive.SubmissionsTable do
  @moduledoc false

  # TODO: Figure out why this has to be a live component to receive a socket assign
  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true
  prop return_url, :string, default: nil

  prop delete, :event, required: true
end
