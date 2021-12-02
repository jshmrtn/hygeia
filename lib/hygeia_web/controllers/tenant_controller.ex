defmodule HygeiaWeb.TenantController do
  use HygeiaWeb, :controller

  import HygeiaWeb.Helpers.Export

  alias Hygeia.CaseContext
  alias Hygeia.Repo
  alias Hygeia.TenantContext

  @formats [:bag_med_16122020_case, :bag_med_16122020_contact, :breakthrough_infection]
  @string_formats Enum.map(@formats, &Atom.to_string/1)

  @spec export(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def export(conn, %{"id" => tenant_uuid, "format" => format} = params)
      when format in @string_formats do
    tenant = TenantContext.get_tenant!(tenant_uuid)

    format = String.to_existing_atom(format)

    if authorized?(tenant, :export_data, get_auth(conn), format: format) do
      extended = params["extended"] == "true"

      export(conn, tenant, format, extended)
    else
      conn
      |> redirect(to: Routes.home_index_path(conn, :index))
      |> put_flash(:error, gettext("You are not authorized to do this action."))
    end
  end

  defp export(conn, tenant, format, extended) do
    {:ok, conn} =
      Repo.transaction(fn ->
        {:ok, conn} =
          conn
          |> put_resp_header(
            "content-disposition",
            "attachment; filename=#{format} - #{tenant.name} - #{DateTime.utc_now()}.csv"
          )
          |> put_resp_content_type("text/csv")
          |> send_chunked(200)
          |> chunk(:unicode.encoding_to_bom(:utf8))

        tenant
        |> CaseContext.case_export(format, extended)
        |> into_conn(conn)
      end)

    conn
  end
end
