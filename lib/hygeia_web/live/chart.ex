defmodule HygeiaWeb.Chart do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop config, :map, required: true
  prop dom_id, :string, required: true

  prop enable_vision_impaired_mode, :boolean,
    from_context: {__MODULE__, :enable_vision_impaired_mode}

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~F"""
    <div>
      {content_tag(
        :div,
        "",
        id: @dom_id <> "_hook",
        "phx-hook": "Chart",
        hidden: true,
        data: [
          chart:
            @config
            |> Map.put(:id, @dom_id <> "_chart")
            |> Map.update(:chart, %{height: "50%"}, &Map.put_new(&1, :height, "50%"))
            |> Map.put_new(:enableVisionImpairedMode, @enable_vision_impaired_mode)
            |> Jason.encode!()
        ]
      )}
      <div phx-update="ignore" id={"#{@dom_id}_ignore"} class="position-relative chart-container">
        <canvas id={"#{@dom_id}_chart"} />
      </div>
    </div>
    """
  end
end
