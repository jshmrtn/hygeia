defmodule HygeiaWeb.SendCaseClosedEmailUrlGenerator do
  @moduledoc false

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.TenantContext
  alias HygeiaWeb.Router.Helpers, as: Routes

  @spec pdf_url(case :: Case.t(), phase :: Phase.t()) :: String.t()
  def pdf_url(case, phase) do
    TenantContext.replace_base_url(
      case.tenant,
      Routes.pdf_url(HygeiaWeb.Endpoint, :isolation_end_confirmation, case, phase),
      HygeiaWeb.Endpoint.url()
    )
  end
end
