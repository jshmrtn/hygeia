defmodule HygeiaWeb.StatisticsController do
  use HygeiaWeb, :controller

  import HygeiaWeb.Helpers.Export

  alias Hygeia.Repo
  alias Hygeia.StatisticsContext
  alias Hygeia.TenantContext

  @types [
    :active_isolation_cases_per_day,
    :cumulative_index_case_end_reasons,
    :active_quarantine_cases_per_day,
    :active_hospitalization_cases_per_day,
    :cumulative_possible_index_case_end_reasons,
    :new_cases_per_day,
    :active_complexity_cases_per_day,
    :active_infection_place_cases_per_day,
    :transmission_country_cases_per_day,
    :active_cases_per_day_and_organisation,
    :vaccination_breakthroughs_per_day
  ]
  @string_types Enum.map(@types, &Atom.to_string/1)

  @spec export(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def export(conn, %{"tenant_uuid" => tenant_uuid, "type" => type, "from" => from, "to" => to})
      when type in @string_types do
    from = Date.from_iso8601!(from)
    to = Date.from_iso8601!(to)
    type = String.to_existing_atom(type)
    tenant = TenantContext.get_tenant!(tenant_uuid)

    if authorized?(tenant, :statistics, get_auth(conn)) do
      export(conn, tenant, type, from, to)
    else
      conn
      |> redirect(to: Routes.home_index_path(conn, :index))
      |> put_flash(:error, gettext("You are not authorized to do this action."))
    end
  end

  defp export(conn, tenant, type, from, to) do
    {:ok, conn} =
      Repo.transaction(fn ->
        {:ok, conn} =
          conn
          |> put_resp_header(
            "content-disposition",
            "attachment; filename=#{type}_#{tenant.name}_#{from}_#{to}.csv"
          )
          |> put_resp_content_type("text/csv")
          |> send_chunked(200)
          |> chunk(:unicode.encoding_to_bom(:utf8))

        type
        |> StatisticsContext.export(tenant, from, to)
        |> into_conn(conn)
      end)

    conn
  end
end
