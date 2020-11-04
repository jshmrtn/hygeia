defmodule HygeiaWeb.PdfController do
  use HygeiaWeb, :controller

  import Hygeia.CaseContext

  alias Hygeia.CaseContext.Phase
  alias HygeiaPdfConfirmation.Isolation
  alias HygeiaPdfConfirmation.Quarantine

  @spec isolation_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def isolation_confirmation(conn, %{"case_uuid" => case_uuid, "phase_uuid" => phase_uuid}) do
    case = get_case!(case_uuid)

    case.phases
    |> Enum.find(&match?(%Phase{uuid: ^phase_uuid}, &1))
    |> case do
      nil ->
        raise "not found"

      %Phase{} = phase ->
        conn
        |> put_resp_header("content-type", "application/pdf")
        |> put_resp_header("content-disposition", "attachment")
        |> send_resp(:ok, Isolation.render_pdf(case, phase))
    end
  end

  @spec quarantine_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def quarantine_confirmation(conn, %{"case_uuid" => case_uuid, "phase_uuid" => phase_uuid}) do
    case = get_case!(case_uuid)

    case.phases
    |> Enum.find(&match?(%Phase{uuid: ^phase_uuid}, &1))
    |> case do
      nil ->
        raise "not found"

      %Phase{} = phase ->
        conn
        |> put_resp_header("content-type", "application/pdf")
        |> put_resp_header("content-disposition", "attachment")
        |> send_resp(:ok, Quarantine.render_pdf(case, phase))
    end
  end
end
