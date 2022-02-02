defmodule HygeiaWeb.Helpers.AutoTracing do
  @moduledoc "Helpers for Auto Tracing"

  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias HygeiaWeb.Router.Helpers, as: Routes

  @type route ::
          (conn :: Plug.Conn.t() | Phoenix.LiveView.Socket.t(), case_uuid :: Ecto.UUID.t() ->
             String.t())

  @available_steps [
    %{step: :start, route: &Routes.auto_tracing_start_path/3},
    %{step: :address, route: &Routes.auto_tracing_address_path/3},
    %{
      step: :contact_methods,
      route: &Routes.auto_tracing_contact_methods_path/3
    },
    %{step: :visits, route: &Routes.auto_tracing_visits_path/3},
    %{step: :employer, route: &Routes.auto_tracing_employer_path/3},
    %{step: :vaccination, route: &Routes.auto_tracing_vaccination_path/3},
    %{step: :covid_app, route: &Routes.auto_tracing_covid_app_path/3},
    %{step: :clinical, route: &Routes.auto_tracing_clinical_path/3},
    %{step: :travel, route: &Routes.auto_tracing_travel_path/3},
    %{step: :transmission, route: &Routes.auto_tracing_transmission_path/3},
    %{
      step: :contact_persons,
      route: &Routes.auto_tracing_contact_persons_path/3
    },
    %{step: :end, route: &Routes.auto_tracing_end_path/3}
  ]

  @spec get_next_step_route(step :: Step.t()) :: route() | nil
  def get_next_step_route(step),
    do: step |> Step.get_next_step() |> get_step_route()

  @spec get_previous_step_route(step :: Step.t()) :: route() | nil
  def get_previous_step_route(step),
    do: step |> Step.get_previous_step() |> get_step_route()

  @spec get_step_route(step :: Step.t()) :: route() | nil
  def get_step_route(step) do
    @available_steps
    |> Enum.filter(&(&1.step in Step.publicly_available_steps()))
    |> Enum.find(&(&1.step == step))
    |> case do
      nil -> nil
      %{route: route} -> &route.(&1, step, &2)
    end
  end
end
