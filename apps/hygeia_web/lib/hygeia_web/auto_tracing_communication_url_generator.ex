defmodule HygeiaWeb.AutoTracingCommunicationUrlGenerator do
  @moduledoc false

  alias Hygeia.CaseContext.Case
  alias Hygeia.TenantContext
  alias HygeiaWeb.Router.Helpers, as: Routes

  @spec overview_url(case :: Case.t()) :: String.t()
  def overview_url(case) do
    TenantContext.replace_base_url(
      case.tenant,
      Routes.person_overview_index_url(HygeiaWeb.Endpoint, :index, case.person_uuid),
      HygeiaWeb.Endpoint.url()
    )
  end
end
