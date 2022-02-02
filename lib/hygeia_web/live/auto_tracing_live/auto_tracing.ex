defmodule HygeiaWeb.AutoTracingLive.AutoTracing do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.AutoTracing, only: [get_step_route: 1]

  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo

  defmodule AutoTracingNotFoundError do
    @moduledoc false
    defexception plug_status: 404,
                 message: "auto tracing not found",
                 case_uuid: nil

    @impl Exception
    def exception(opts) do
      case_uuid = Keyword.fetch!(opts, :case_uuid)

      %__MODULE__{
        message: "the auto tracing was not found for the case #{case_uuid}",
        case_uuid: case_uuid
      }
    end
  end

  defmodule CaseClosedError do
    @moduledoc false
    defexception plug_status: 403,
                 message: "Forbidden as case closed",
                 case_uuid: nil

    @impl Exception
    def exception(opts) do
      case_uuid = Keyword.fetch!(opts, :case_uuid)

      %__MODULE__{
        message: "the link is no longer available as the case #{case_uuid} is closed",
        case_uuid: case_uuid
      }
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~F"""
    <span>{gettext("Redirecting")}</span>
    """
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], tests: [:mutation], auto_tracing: [])

    socket =
      cond do
        Case.closed?(case) ->
          raise CaseClosedError, case_uuid: case.uuid

        is_nil(case.auto_tracing) ->
          raise AutoTracingNotFoundError, case_uuid: case.uuid

        !authorized?(case, :auto_tracing, get_auth(socket)) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
              )
          )

        case.auto_tracing.last_completed_step not in Step.publicly_available_steps() ->
          push_redirect(socket,
            to: get_step_route(:start).(socket, case.uuid)
          )

        true ->
          push_redirect(socket,
            to: get_step_route(case.auto_tracing.last_completed_step).(socket, case.uuid)
          )
      end

    {:noreply, socket}
  end
end
