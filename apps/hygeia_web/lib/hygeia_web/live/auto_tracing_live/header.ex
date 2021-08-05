defmodule HygeiaWeb.AutoTracingLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.LiveRedirect

  prop auto_tracing, :map, required: true

  data changeset, :map

  @impl Phoenix.LiveComponent
  def update(%{auto_tracing: auto_tracing} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: AutoTracing.changeset(auto_tracing))}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}
end
