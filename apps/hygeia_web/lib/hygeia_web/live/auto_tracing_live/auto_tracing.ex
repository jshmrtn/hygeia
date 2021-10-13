defmodule HygeiaWeb.AutoTracingLive.AutoTracing do
  @moduledoc false

  use HygeiaWeb, :surface_view

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

  defp route(nil), do: &Routes.auto_tracing_start_path(&1, :start, &2)
  defp route(:start), do: &Routes.auto_tracing_start_path(&1, :start, &2)
  defp route(:address), do: &Routes.auto_tracing_address_path(&1, :address, &2)

  defp route(:contact_methods),
    do: &Routes.auto_tracing_contact_methods_path(&1, :contact_methods, &2)

  defp route(:employer), do: &Routes.auto_tracing_employer_path(&1, :employer, &2)
  defp route(:vaccination), do: &Routes.auto_tracing_vaccination_path(&1, :vaccination, &2)
  defp route(:covid_app), do: &Routes.auto_tracing_covid_app_path(&1, :covid_app, &2)
  defp route(:clinical), do: &Routes.auto_tracing_clinical_path(&1, :clinical, &2)
  defp route(:flights), do: &Routes.auto_tracing_flights_path(&1, :flights, &2)

  defp route(:transmission), do: &Routes.auto_tracing_transmission_path(&1, :transmission, &2)

  defp route(:contact_persons),
    do: &Routes.auto_tracing_contact_persons_path(&1, :contact_persons, &2)

  defp route(:end), do: &Routes.auto_tracing_end_path(&1, :end, &2)

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

        true ->
          push_redirect(socket,
            to: route(case.auto_tracing.last_completed_step).(socket, case.uuid)
          )
      end

    {:noreply, socket}
  end
end
