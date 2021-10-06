defmodule HygeiaWeb.PdfController do
  use HygeiaWeb, :controller

  import Hygeia.CaseContext

  alias Hygeia.AuditContext
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.Repo
  alias HygeiaPdfConfirmation.Isolation
  alias HygeiaPdfConfirmation.IsolationEnd
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

  defmodule DocumentCurrentlyUnavailableError do
    @moduledoc false
    defexception plug_status: 409,
                 message: "currently unavailable",
                 conn: nil,
                 case_uuid: nil,
                 phase_uuid: nil

    @impl Exception
    def exception(opts) do
      conn = Keyword.fetch!(opts, :conn)
      case_uuid = Keyword.fetch!(opts, :case_uuid)
      phase_uuid = Keyword.fetch!(opts, :phase_uuid)

      %__MODULE__{
        message:
          "requested document is currently unavailable, due to wrong or missing parameters for phase with id #{phase_uuid} of the case #{case_uuid} or if an end confirmation is requested more than one day before phase end",
        conn: conn,
        case_uuid: case_uuid,
        phase_uuid: phase_uuid
      }
    end
  end

  @spec isolation_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def isolation_confirmation(conn, params), do: confirmation(conn, params, Isolation)

  @spec quarantine_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def quarantine_confirmation(conn, params), do: confirmation(conn, params, Quarantine)

  @spec isolation_end_confirmation(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) ::
          Plug.Conn.t()
  def isolation_end_confirmation(conn, params), do: confirmation(conn, params, IsolationEnd)

  # sobelow_skip ["XSS.SendResp"]
  defp confirmation(
         %Plug.Conn{request_path: request_path} = conn,
         %{
           "case_uuid" => case_uuid,
           "phase_uuid" => phase_uuid
         },
         confirmation_type
       ) do
    case =
      case_uuid
      |> get_case!()
      |> Repo.preload(:tenant)

    if authorized?(case, :partial_details, get_auth(conn)) do
      AuditContext.log_view(
        Logger.metadata()[:request_id],
        get_auth(conn),
        conn.remote_ip,
        current_url(conn),
        :details,
        case
      )

      case.phases
      |> Enum.find(&match?(%Phase{uuid: ^phase_uuid}, &1))
      |> case do
        nil ->
          raise PhaseNotFoundError, conn: conn, phase_uuid: phase_uuid, case_uuid: case_uuid

        %Phase{} = phase ->
          if (IsolationEnd == confirmation_type and
                Phase.can_generate_pdf_end_confirmation?(phase, case.tenant)) or
               (IsolationEnd != confirmation_type and
                  Phase.can_generate_pdf_confirmation?(phase, case.tenant)) do
            conn
            |> put_resp_header("content-type", "application/pdf")
            |> put_resp_header("content-disposition", "attachment")
            |> send_resp(:ok, confirmation_type.render_pdf(case, phase))
          else
            raise DocumentCurrentlyUnavailableError,
              conn: conn,
              phase_uuid: phase_uuid,
              case_uuid: case_uuid
          end
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
