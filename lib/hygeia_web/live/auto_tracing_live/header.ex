defmodule HygeiaWeb.AutoTracingLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import HygeiaWeb.Helpers.AutoTracing, only: [get_step_route: 1]

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias HygeiaWeb.UriActiveContext

  alias Surface.Components.LiveRedirect

  prop auto_tracing, :map, required: true

  @impl Phoenix.LiveComponent
  def update(assigns, socket), do: {:ok, assign(socket, assigns)}
end
