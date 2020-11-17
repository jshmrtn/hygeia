defmodule HygeiaPdfConfirmation.Isolation do
  @moduledoc """
  Create Isolation Confirmation PDF
  """

  import HygeiaPdfConfirmation.IsolationView

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo

  @spec render_pdf(case :: Case.t(), phase :: Phase.t()) :: binary
  def render_pdf(%Case{} = case, %Phase{} = phase) do
    case = Repo.preload(case, person: [])

    "confirmation.html"
    |> render(case: case, phase: phase)
    |> Phoenix.HTML.safe_to_string()
    |> PdfGenerator.generate_binary!(delete_temporary: true)
  end
end
