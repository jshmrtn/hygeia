defmodule HygeiaWeb.Chart do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop config, :map, required: true
  prop dom_id, :string, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    {{ content_tag(
      :div,
      "",
      id: @dom_id <> "_hook",
      "phx-hook": "Chart",
      hidden: true,
      data: [
        chart: @config
        |> Map.put(:id, @dom_id <> "_chart")
        |> Map.update(:credits, %{enabled: false}, &Map.put_new(&1, :enabled, false))
        |> Map.update(:chart, %{height: "60%"}, &Map.put_new(&1, :height, "50%"))
        |> Jason.encode!()
      ]
    ) }}
    <div phx-update="ignore" id={{ @dom_id <> "_ignore" }} class="position-relative chart-container">
      <canvas id={{ @dom_id <> "_chart" }}></canvas>
    </div>
    """
  end
end
