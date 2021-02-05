defmodule HygeiaPdfConfirmation.Quarantine do
  @moduledoc """
  Create Quarantine Confirmation PDF
  """

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias HygeiaPdfConfirmation.QuarantineView

  @spec render_pdf(case :: Case.t(), phase :: Phase.t()) :: binary
  def render_pdf(%Case{} = case, %Phase{} = phase) do
    case =
      Repo.preload(case,
        person: [employers: []],
        tenant: [],
        received_transmissions: []
      )

    case.tenant.template_variation
    |> case do
      nil -> hd(HygeiaPdfConfirmation.available_variations())
      other -> other
    end
    |> HygeiaPdfConfirmation.render_pdf(QuarantineView, "confirmation.html",
      case: case,
      phase: phase,
      document_name: gettext("Quarantine Order")
    )
  end
end
