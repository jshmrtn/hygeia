defmodule HygeiaWeb.PdfController do
  use HygeiaWeb, :controller

  import Hygeia.CaseContext

  alias Hygeia.CaseContext.Case.Phase
  alias HygeiaPdfConfirmation.Isolation
  alias HygeiaPdfConfirmation.Quarantine

  defmodule PhaseNotFoundError do
    @moduledoc false
    defexception plug_status: 404,
                 message: "phase not found",
                 conn: nil,
                 case_uuid: nil,
                 phase_uuid: nil

    @impl Exception
    def exception(opts) do
      conn = Keyword.fetch!(opts, :conn)
      case_uuid = Keyword.fetch!(opts, :case_uuid)
      phase_uuid = Keyword.fetch!(opts, :phase_uuid)

      %__MODULE__{
        message: "the phase with id #{phase_uuid} was not found in the case #{case_uuid}",
        conn: conn,
        case_uuid: case_uuid,
        phase_uuid: phase_uuid
      }
    end
  end

  @spec isolation_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def isolation_confirmation(%Plug.Conn{request_path: request_path} = conn, %{
        "case_uuid" => case_uuid,
        "phase_uuid" => phase_uuid
      }) do
    case = get_case!(case_uuid)

    if authorized?(case, :partial_details, get_auth(conn)) do
      case.phases
      |> Enum.find(&match?(%Phase{uuid: ^phase_uuid}, &1))
      |> case do
        nil ->
          raise PhaseNotFoundError, conn: conn, phase_uuid: phase_uuid, case_uuid: case_uuid

        %Phase{} = phase ->
          conn
          |> put_resp_header("content-type", "application/pdf")
          |> put_resp_header("content-disposition", "attachment")
          |> send_resp(:ok, Isolation.render_pdf(case, phase))
      end
    else
      redirect(conn,
        to:
          Routes.auth_login_path(conn, :login,
            person_uuid: case.person_uuid,
            return_url: request_path
          )
      )
    end
  end

  @spec quarantine_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def quarantine_confirmation(%Plug.Conn{request_path: request_path} = conn, %{
        "case_uuid" => case_uuid,
        "phase_uuid" => phase_uuid
      }) do
    case = get_case!(case_uuid)

    if authorized?(case, :partial_details, get_auth(conn)) do
      case.phases
      |> Enum.find(&match?(%Phase{uuid: ^phase_uuid}, &1))
      |> case do
        nil ->
          raise PhaseNotFoundError, conn: conn, phase_uuid: phase_uuid, case_uuid: case_uuid

        %Phase{} = phase ->
          conn
          |> put_resp_header("content-type", "application/pdf")
          |> put_resp_header("content-disposition", "attachment")
          |> send_resp(:ok, Quarantine.render_pdf(case, phase))
      end
    else
      redirect(conn,
        to:
          Routes.auth_login_path(conn, :login,
            person_uuid: case.person_uuid,
            return_url: request_path
          )
      )
    end
  end
end
