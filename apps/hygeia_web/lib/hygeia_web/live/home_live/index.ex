defmodule HygeiaWeb.HomeLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.Helpers.Tenant, as: TenantHelper
  alias Surface.Components.Link

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
             TenantContext.list_tenants()
             |> Enum.filter(&match?(%Tenant{case_management_enabled: true}, &1))
             |> Enum.reject(&match?(%Tenant{iam_domain: nil}, &1))
             |> Enum.filter(&TenantHelper.logo_exists?/1)
         )}
    end
  end
end
