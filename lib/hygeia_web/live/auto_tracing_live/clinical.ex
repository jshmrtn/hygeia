defmodule HygeiaWeb.AutoTracingLive.Clinical do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CommunicationContext
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.LiveRedirect

  @days_before_test 6

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(
        person: [],
        hospitalizations: [organisation: []],
        auto_tracing: [],
        tests: []
      )

    socket =
      cond do
        Case.closed?(case) ->
          raise HygeiaWeb.AutoTracingLive.AutoTracing.CaseClosedError, case_uuid: case.uuid

        !authorized?(case, :auto_tracing, get_auth(socket)) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
              )
          )

        !AutoTracing.step_available?(case.auto_tracing, :clinical) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          assign(socket,
            case: case,
            changeset: %Ecto.Changeset{
              CaseContext.change_case(case, %{}, %{symptoms_required: true})
              | action: :validate
            },
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"case" => case_params}, socket) do
    case_params = Map.put_new(case_params, "hospitalizations", [])

    {:noreply,
     assign(
       socket,
       :changeset,
       %Ecto.Changeset{
         CaseContext.change_case(socket.assigns.case, case_params, %{symptoms_required: true})
         | action: :validate
       }
     )}
  end

  def handle_event(
        "add_hospitalization",
        _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Ecto.Changeset{
         CaseContext.change_case(
           case,
           changeset_add_to_params(changeset, :hospitalizations, %{
             uuid: Ecto.UUID.generate()
           }),
           %{symptoms_required: true}
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_hospitalization",
        %{"changeset-uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Ecto.Changeset{
         CaseContext.change_case(
           case,
           changeset_remove_from_params_by_id(changeset, :hospitalizations, %{uuid: uuid}),
           %{symptoms_required: true}
         )
         | action: :validate
       }
     )}
  end

  def handle_event("advance", _params, socket) do
    {:ok, case} =
      CaseContext.update_case(
        %Ecto.Changeset{socket.assigns.changeset | action: nil},
        %{},
        %{symptoms_required: true}
      )

    case = Repo.preload(case, hospitalizations: [], tests: [])

    {phase_start, phase_end, problems} = index_phase_dates(case)

    changeset =
      case
      |> shorten_phases_before(phase_start)
      |> append_phase(phase_start, phase_end)

    {:ok, case} = CaseContext.update_case(case, changeset)

    :ok = send_notifications(case, socket)

    {:ok, _auto_tracing} =
      if Enum.any?(problems, &match?(:phase_date_inconsistent, &1)) do
        AutoTracingContext.auto_tracing_add_problem(
          socket.assigns.auto_tracing,
          :phase_date_inconsistent
        )
      else
        AutoTracingContext.auto_tracing_remove_problem(
          socket.assigns.auto_tracing,
          :phase_date_inconsistent
        )
      end

    {:ok, auto_tracing} =
      case case do
        %Case{hospitalizations: [_hospitalization | _others]} ->
          AutoTracingContext.auto_tracing_add_problem_if_not_exists(
            socket.assigns.auto_tracing,
            :hospitalization
          )

        %Case{} ->
          AutoTracingContext.auto_tracing_remove_problem(
            socket.assigns.auto_tracing,
            :hospitalization
          )
      end

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :clinical)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_flights_path(
           socket,
           :flights,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:hospitalisation_change_organisation, uuid, organisation_uuid},
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Ecto.Changeset{
         CaseContext.change_case(
           case,
           changeset_update_params_by_id(
             changeset,
             :hospitalizations,
             %{uuid: uuid},
             &Map.put(&1, "organisation_uuid", organisation_uuid)
           )
         )
         | action: :validate
       }
     )}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp append_phase(changeset, phase_start, phase_end) do
    index_phase =
      Enum.find(
        Ecto.Changeset.fetch_field!(changeset, :phases),
        &match?(%Case.Phase{details: %Case.Phase.Index{}}, &1)
      )

    changeset_update_params_by_id(changeset, :phases, %{uuid: index_phase.uuid}, fn params ->
      Map.merge(params, %{
        "quarantine_order" => true,
        "start" => phase_start,
        "end" => phase_end
      })
    end)
  end

  defp shorten_phases_before(case, phase_start) do
    Enum.reduce(case.phases, CaseContext.change_case(case), fn
      %Case.Phase{
        quarantine_order: true,
        uuid: phase_before_uuid,
        start: phase_before_start,
        end: phase_before_end
      },
      acc ->
        case {Date.compare(phase_before_start, phase_start),
              Date.compare(phase_before_end, phase_start)} do
          {:gt, _cmp_end} ->
            CaseContext.change_case(
              acc,
              changeset_update_params_by_id(
                acc,
                :phases,
                %{uuid: phase_before_uuid},
                &Map.merge(&1, %{"end" => nil, "start" => nil, "quarantine_order" => false})
              )
            )

          {_cmp_start, :gt} ->
            CaseContext.change_case(
              acc,
              changeset_update_params_by_id(
                acc,
                :phases,
                %{uuid: phase_before_uuid},
                &Map.merge(&1, %{"end" => phase_start})
              )
            )

          _other ->
            acc
        end

      %Case.Phase{}, acc ->
        acc
    end)
  end

  defp index_phase_dates(case) do
    {start_date, problems} = index_phase_start_date(case, days_before_test: @days_before_test)

    phase_start = Date.utc_today()
    phase_end = Date.add(start_date, 9)

    phase_end =
      case Date.compare(phase_end, phase_start) do
        :lt -> phase_start
        _other -> phase_end
      end

    {phase_start, phase_end, problems}
  end

  defp index_phase_start_date(
         %Case{clinical: %Case.Clinical{symptom_start: %Date{} = symptom_start}, tests: tests},
         opts
       ) do
    days_before_test = Keyword.get(opts, :days_before_test)

    problems =
      tests
      |> Enum.map(&(&1.tested_at || &1.laboratory_reported_at))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort({:asc, Date})
      |> case do
        [] ->
          []

        [date | _others] ->
          if Date.diff(date, symptom_start) >= days_before_test do
            [:phase_date_inconsistent]
          else
            []
          end
      end

    {symptom_start, problems}
  end

  defp index_phase_start_date(%Case{tests: tests, phases: phases}, _opts) do
    index_phase = Enum.find(phases, &match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))

    start_date =
      tests
      |> Enum.map(&(&1.tested_at || &1.laboratory_reported_at))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort({:asc, Date})
      |> case do
        [] -> DateTime.to_date(index_phase.inserted_at)
        [date | _others] -> date
      end

    {start_date, []}
  end

  defp send_notifications(case, socket) do
    case = Repo.preload(case, person: [])

    index_phase = Enum.find(case.phases, &match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))

    :ok =
      case
      |> CommunicationContext.create_outgoing_sms(isolation_sms(socket, case, index_phase))
      |> case do
        {:ok, _sms} -> :ok
        {:error, :no_mobile_number} -> :ok
        {:error, :sms_config_missing} -> :ok
      end

    :ok =
      case
      |> CommunicationContext.create_outgoing_email(
        isolation_email_subject(),
        isolation_email_body(socket, case, index_phase, :email)
      )
      |> case do
        {:ok, _email} -> :ok
        {:error, :no_email} -> :ok
        {:error, :no_outgoing_mail_configuration} -> :ok
      end
  end
end
