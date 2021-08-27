defmodule HygeiaWeb.RelativeTime do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop time, :map, required: true
  prop component_id, :string, required: true

  data now, :map

  @impl Phoenix.LiveComponent
  def mount(socket), do: {:ok, assign(socket, now: DateTime.utc_now())}

  @impl Phoenix.LiveComponent
  def render(assigns) do
    send_update_after(
      __MODULE__,
      [id: assigns.component_id, now: DateTime.utc_now()],
      :timer.seconds(1)
    )

    ~F"""
    <Context get={HygeiaWeb, timezone: timezone}>
      <time
        datetime={DateTime.to_iso8601(@time)}
        title={@time |> DateTime.shift_zone!(timezone) |> HygeiaCldr.DateTime.to_string!()}
      >
        {HygeiaCldr.DateTime.Relative.to_string!(@time,
          format: :short,
          relative_to: @now
        )}
      </time>
    </Context>
    """
  end
end
