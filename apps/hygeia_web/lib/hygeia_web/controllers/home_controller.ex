defmodule HygeiaWeb.HomeController do
  use HygeiaWeb, :controller

  import Hygeia.Authorization
  import HygeiaWeb.Helpers.Auth

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    auth =
      conn
      |> get_auth
      |> case do
        nil -> :anonymous
        user -> user
      end

    cond do
      authorized?(Hygeia.CaseContext.Case, :list, auth, tenant: :any) ->
        redirect(conn, to: Routes.case_index_path(conn, :index))

      authorized?(Hygeia.CaseContext.Person, :list, auth, tenant: :any) ->
        redirect(conn, to: Routes.person_index_path(conn, :index))

      authorized?(Hygeia.TenantContext.Tenant, :list, auth) ->
        redirect(conn, to: Routes.statistics_choose_tenant_path(conn, :index))

      true ->
        redirect(conn, to: Routes.auth_path(conn, :request, "oidc"))
    end
  end
end
