defmodule HygeiaPdfConfirmation.Isolation do
  @moduledoc """
  Create Isolation Confirmation PDF
  """

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias HygeiaPdfConfirmation.IsolationView

  @spec render_pdf(case :: Case.t(), phase :: Phase.t()) :: binary
  def render_pdf(%Case{} = case, %Phase{} = phase) do
    case = Repo.preload(case, person: [])

    HygeiaPdfConfirmation.render_pdf(IsolationView, "confirmation.html",
      case: case,
      phase: phase,
      document_name: gettext("Isolation Order")
    )
  end
end
