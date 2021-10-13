defmodule HygeiaWeb.AutoTracingLive.Flights do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  import Ecto.Changeset

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Flight
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :has_flown, :boolean
    embeds_many :flights, Flight, on_replace: :delete
  end

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [:affiliations], auto_tracing: [], tests: [])

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

        !AutoTracing.step_available?(case.auto_tracing, :flights) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          step = %__MODULE__{
            has_flown: case.auto_tracing.has_flown,
            flights: case.auto_tracing.flights
          }

          assign(socket,
            case: case,
            step: step,
            changeset: %Ecto.Changeset{changeset(step) | action: :validate},
            # person: case.person,
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "add_flight",
        _params,
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Changeset{
         changeset(
           step,
           changeset_add_to_params(changeset, :flights, %{
             uuid: Ecto.UUID.generate()
           })
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_flight",
        %{"value" => flight_uuid},
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_remove_from_params_by_id(changeset, :flights, %{uuid: flight_uuid})
         )
         | action: :validate
       }
     )}
  end

  def handle_event("validate", %{"flights" => params}, socket) do
    params = Map.put_new(params, "flights", [])

    {:noreply,
     assign(socket,
       changeset: %Changeset{changeset(socket.assigns.step, params) | action: :validate}
     )}
  end

  def handle_event(
        "advance",
        _params,
        %Socket{assigns: %{changeset: changeset, auto_tracing: auto_tracing}} = socket
      ) do
    socket =
      changeset
      |> apply_action(:compute)
      |> case do
        {:error, changeset} ->
          assign(socket, changeset: changeset)

        {:ok, step} ->
          auto_tracing_changeset =
            auto_tracing
            |> AutoTracingContext.change_auto_tracing()
            |> put_change(:has_flown, step.has_flown)
            |> put_embed(:flights, step.flights)

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          {:ok, auto_tracing} =
            if auto_tracing.has_flown do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(auto_tracing, :flight_related)
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :flight_related)
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :flights)

          push_redirect(socket,
            to:
              Routes.auto_tracing_transmission_path(
                socket,
                :transmission,
                socket.assigns.auto_tracing.case_uuid
              )
          )
      end

    {:noreply, socket}
  end

  defp generate_flight_question(%Case{
         clinical: %Clinical{has_symptoms: true, symptom_start: start_date}
       }) do
    generate_question(start_date, calculate_end_date(start_date))
  end

  defp generate_flight_question(
         %Case{tests: tests, clinical: %Clinical{has_symptoms: false}} = case
       )
       when is_list(tests) and length(tests) > 0 do
    start_date =
      tests
      |> Enum.reject(&(&1.result == :negative))
      |> Enum.sort(&(&1.laboratory_reported_at >= &2.laboratory_reported_at))
      |> List.first()
      |> case do
        nil ->
          case.inserted_at

        positive_test ->
          if positive_test.tested_at do
            positive_test.tested_at
          else
            positive_test.laboratory_reported_at
          end
      end

    generate_question(start_date, calculate_end_date(start_date))
  end

  defp generate_flight_question(%Case{inserted_at: start_date}) do
    generate_question(start_date, calculate_end_date(start_date))
  end

  defp generate_question(start_date, end_date) do
    gettext("Did you travel by plane between %{start_date} and %{end_date}?",
      start_date: HygeiaCldr.Date.to_string!(start_date),
      end_date: HygeiaCldr.Date.to_string!(end_date)
    )
  end

  defp calculate_end_date(start_date) do
    start_date
    |> Date.add(2)
    |> Kernel.then(fn result_date ->
      result_date
      |> Date.compare(Date.utc_today())
      |> case do
        :gt -> Date.utc_today()
        _else -> result_date
      end
    end)
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:has_flown])
    |> validate_required([:has_flown])
    |> validate_flight()
  end

  defp validate_flight(changeset) do
    changeset
    |> fetch_field!(:has_flown)
    |> case do
      true ->
        cast_embed(changeset, :flights,
          required: true,
          required_message:
            gettext(
              "please add at least one flight that you took during the period in consideration"
            )
        )

      _else ->
        changeset
    end
  end
end
