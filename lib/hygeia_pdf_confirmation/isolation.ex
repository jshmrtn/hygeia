defmodule HygeiaPdfConfirmation.Isolation do
  @moduledoc """
  Create Isolation Confirmation PDF
  """

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant

  @spec render_pdf(case :: Case.t(), phase :: Phase.t()) :: binary
  def render_pdf(%Case{} = case, %Phase{} = phase) do
    %Case{tenant: %Tenant{template_variation: template_variation}} =
      case = Repo.preload(case, person: [employers: []], tenant: [], tests: [])

    HygeiaPdfConfirmation.render_pdf(template_variation, "isolation",
      case: case,
      phase: phase,
      document_name: gettext("Isolation Order")
    )
  end
end
