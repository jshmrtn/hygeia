defmodule HygeiaWeb.AutoTracingLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.LiveRedirect

  prop auto_tracing, :map, required: true

  data steps, :list,
    default: [
      %{step: :start, route: &Routes.auto_tracing_start_path/3},
      %{step: :address, route: &Routes.auto_tracing_address_path/3},
      %{step: :contact_methods, route: &Routes.auto_tracing_contact_methods_path/3},
      %{step: :visits, route: &Routes.auto_tracing_visits_path/3},
      %{step: :employer, route: &Routes.auto_tracing_employer_path/3},
      %{step: :vaccination, route: &Routes.auto_tracing_vaccination_path/3},
      %{step: :covid_app, route: &Routes.auto_tracing_covid_app_path/3},
      %{step: :clinical, route: &Routes.auto_tracing_clinical_path/3},
      %{step: :flights, route: &Routes.auto_tracing_flights_path/3},
      %{step: :transmission, route: &Routes.auto_tracing_transmission_path/3},
      %{step: :contact_persons, route: &Routes.auto_tracing_contact_persons_path/3},
      %{step: :end, route: &Routes.auto_tracing_end_path/3}
    ]

  @impl Phoenix.LiveComponent
  def update(assigns, socket), do: {:ok, assign(socket, assigns)}
end
