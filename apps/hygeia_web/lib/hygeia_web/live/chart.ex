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
        |> Map.put_new(:credits, %{enabled: false})
        |> Jason.encode!()
      ]
    ) }}
    <div phx-update="ignore" id={{ @dom_id <> "_ignore" }}>
      <div id={{ @dom_id <> "_chart" }}></div>
    </div>
    """
  end
end
