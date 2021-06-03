defmodule HygeiaPdfConfirmation.IsolationEnd do
  @moduledoc """
  Create Isolation End Confirmation PDF
  """

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant

  @spec render_pdf(case :: Case.t(), phase :: Phase.t()) :: binary
  def render_pdf(%Case{} = case, %Phase{} = phase) do
    %Case{tenant: %Tenant{template_variation: template_variation}} =
      case = Repo.preload(case, person: [employers: []], tenant: [])

    HygeiaPdfConfirmation.render_pdf(template_variation, "isolation_end",
      case: case,
      phase: phase,
      document_name: gettext("Isolation End")
    )
  end
end
