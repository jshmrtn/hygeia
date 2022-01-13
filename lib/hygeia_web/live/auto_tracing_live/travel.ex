defmodule HygeiaWeb.AutoTracingLive.Travel do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  import Ecto.Changeset

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Flight
  alias Hygeia.AutoTracingContext.AutoTracing.Travel
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.Repo
  alias Hygeia.RiskCountryContext

  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  alias HygeiaWeb.AutoTracingLive.Travel.PossibleTravel

  defmodule PossibleTravel do
    @moduledoc false

    use Hygeia, :model

    import Ecto.Changeset

    alias Hygeia.AutoTracingContext.AutoTracing.Travel

    embedded_schema do
      embeds_one :travel, Travel, on_replace: :delete
      field :is_selected, :boolean
    end

    @spec changeset(
            schema :: %__MODULE__{} | Changeset.t(),
            attrs :: Hygeia.ecto_changeset_params()
          ) ::
            Ecto.Changeset.t()
    def changeset(schema, attrs \\ %{}) do
      schema
      |> cast(attrs, [:uuid, :is_selected])
      |> fill_uuid()
      |> validate_travel()
    end

    defp validate_travel(changeset) do
      changeset
      |> fetch_field!(:is_selected)
      |> case do
        true ->
          cast_embed(changeset, :travel,
            with: &Travel.changeset(&1, &2, %{require_last_departure_date: true}),
            required: true,
            required_message: gettext("please provide the information about your travel")
          )

        _else ->
          cast_embed(changeset, :travel)
      end
    end
  end

  @primary_key false
  embedded_schema do
    field :has_travelled_in_risk_country, :boolean
    embeds_many :risk_countries_travelled, PossibleTravel, on_replace: :delete

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

        !AutoTracing.step_available?(case.auto_tracing, :travel) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          step = %__MODULE__{
            has_travelled_in_risk_country: case.auto_tracing.has_travelled_in_risk_country,
            risk_countries_travelled: get_risk_countries_travelled(case.auto_tracing.travels),
            has_flown: case.auto_tracing.has_flown,
            flights: case.auto_tracing.flights
          }

          risk_countries = RiskCountryContext.list_risk_countries()

          assign(socket,
            case: case,
            changeset: %Ecto.Changeset{
              changeset(step, %{}, %{risk_countries: not Enum.empty?(risk_countries)})
              | action: :validate
            },
            auto_tracing: case.auto_tracing,
            risk_countries: risk_countries
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "add_flight",
        _params,
        %Socket{assigns: %{changeset: changeset, risk_countries: risk_countries}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Changeset{
         changeset(
           apply_changes(changeset),
           changeset_add_to_params(changeset, :flights, %{
             uuid: Ecto.UUID.generate()
           }),
           %{risk_countries: not Enum.empty?(risk_countries)}
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_flight",
        %{"value" => flight_uuid},
        %Socket{assigns: %{changeset: changeset, risk_countries: risk_countries}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           apply_changes(changeset),
           changeset_remove_from_params_by_id(changeset, :flights, %{uuid: flight_uuid}),
           %{risk_countries: not Enum.empty?(risk_countries)}
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "validate",
        %{"travel" => params},
        %Socket{assigns: %{risk_countries: risk_countries, changeset: changeset}} = socket
      ) do
    params = Map.put_new(params, "flights", [])

    changeset =
      changeset(apply_changes(changeset), params, %{
        risk_countries: not Enum.empty?(risk_countries)
      })

    {:noreply,
     assign(socket,
       changeset: %Changeset{changeset | action: :validate}
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
          travels =
            Enum.reduce(step.risk_countries_travelled, [], fn
              %PossibleTravel{travel: travel, is_selected: true}, acc ->
                acc ++ [travel]

              %PossibleTravel{is_selected: false}, acc ->
                acc
            end)

          auto_tracing_changeset =
            auto_tracing
            |> AutoTracingContext.change_auto_tracing()
            |> put_change(:has_travelled_in_risk_country, step.has_travelled_in_risk_country)
            |> put_embed(:travels, travels)
            |> put_change(:has_flown, step.has_flown)
            |> put_embed(:flights, step.flights)

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          {:ok, auto_tracing} =
            if auto_tracing.has_travelled_in_risk_country do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(
                  auto_tracing,
                  :high_risk_country_travel
                )
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(
                  auto_tracing,
                  :high_risk_country_travel
                )
            end

          {:ok, auto_tracing} =
            if auto_tracing.has_flown do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(auto_tracing, :flight_related)
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :flight_related)
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :travel)

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

  defp generate_flight_question(case) do
    {start_date, end_date} = get_inquiry_dates(case)

    generate_question(start_date, end_date)
  end

  defp get_inquiry_dates(%Case{
         clinical: %Clinical{has_symptoms: true, symptom_start: %Date{} = symptom_start}
       }) do
    {calculate_date(symptom_start, 2, :past), symptom_start}
  end

  defp get_inquiry_dates(%Case{tests: tests, clinical: %Clinical{has_symptoms: false}} = case)
       when is_list(tests) and length(tests) > 0 do
    start_date =
      tests
      |> Enum.reject(&(&1.result == :negative))
      |> Enum.map(&(&1.tested_at || &1.laboratory_reported_at))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort({:desc, Date})
      |> List.first()
      |> case do
        nil ->
          DateTime.to_date(case.inserted_at)

        test_date ->
          test_date
      end
      |> Date.add(-2)

    {start_date, calculate_date(start_date, 2, :future)}
  end

  defp get_inquiry_dates(%Case{inserted_at: inserted_at}) do
    date = DateTime.to_date(inserted_at)
    {calculate_date(date, 2, :past), date}
  end

  defp generate_question(start_date, end_date) do
    gettext("Did you travel by plane between %{start_date} and %{end_date}?",
      start_date: HygeiaCldr.Date.to_string!(start_date),
      end_date: HygeiaCldr.Date.to_string!(end_date)
    )
  end

  defp calculate_date(start_date, days_to_add, :past) do
    Date.add(start_date, -days_to_add)
  end

  defp calculate_date(start_date, days_to_add, :future) do
    start_date
    |> Date.add(days_to_add)
    |> limit_date_to_today()
  end

  defp limit_date_to_today(date) do
    date
    |> Date.compare(Date.utc_today())
    |> case do
      :gt -> Date.utc_today()
      _else -> date
    end
  end

  defp get_risk_countries_travelled(travels) do
    risk_countries = RiskCountryContext.list_risk_countries()

    Enum.map(risk_countries, fn %{country: code} ->
      if travel = Enum.find(travels, &match?(^code, &1.country)) do
        %PossibleTravel{uuid: Ecto.UUID.generate(), travel: travel, is_selected: true}
      else
        %PossibleTravel{
          uuid: Ecto.UUID.generate(),
          travel: %Travel{country: code},
          is_selected: false
        }
      end
    end)
  end

  defp changeset(schema, attrs, %{risk_countries: true} = opts) do
    schema
    |> changeset(attrs, %{opts | risk_countries: false})
    |> cast(attrs, [:has_travelled_in_risk_country])
    |> validate_required([:has_travelled_in_risk_country])
    |> validate_has_traveled()
    |> validate_travels()
  end

  defp changeset(schema, attrs, _opts) do
    schema
    |> cast(attrs, [:has_flown])
    |> validate_required([:has_flown])
    |> validate_flight()
  end

  defp validate_has_traveled(changeset) do
    changeset
    |> fetch_field!(:has_travelled_in_risk_country)
    |> case do
      true ->
        cast_embed(changeset, :risk_countries_travelled)

      _else ->
        changeset
    end
  end

  defp validate_travels(changeset) do
    changeset
    |> fetch_field!(:has_travelled_in_risk_country)
    |> case do
      true ->
        changeset
        |> fetch_field!(:risk_countries_travelled)
        |> Enum.any?(& &1.is_selected)
        |> case do
          true ->
            changeset

          false ->
            add_error(
              changeset,
              :risk_countries_travelled,
              gettext("Please select the countries you have visited")
            )
        end

      _else ->
        all_travels_unselected =
          changeset
          |> fetch_field!(:risk_countries_travelled)
          |> Enum.map(fn selected_travel ->
            PossibleTravel.changeset(selected_travel, %{
              is_selected: false,
              travel: %{country: selected_travel.travel.country, last_departure_date: nil}
            })
          end)

        put_embed(changeset, :risk_countries_travelled, all_travels_unselected)
    end
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
