defmodule HygeiaWeb.HomeLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.Helpers.Tenant, as: TenantHelper
  alias Surface.Components.Link

  data hide_footer, :boolean, default: true
  data no_js_required, :boolean, default: true

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    auth = get_auth(socket)

    cond do
      authorized?(Hygeia.CaseContext.Case, :list, auth, tenant: :any) ->
        {:ok, push_redirect(socket, to: Routes.case_index_path(socket, :index))}

      authorized?(Hygeia.CaseContext.Person, :list, auth, tenant: :any) ->
        {:ok, push_redirect(socket, to: Routes.person_index_path(socket, :index))}

      true ->
        {:ok,
         assign(socket,
           tenants:
             Enum.filter(TenantContext.list_tenants(), &Tenant.is_internal_managed_tenant?/1)
         )}
    end
  end
end
