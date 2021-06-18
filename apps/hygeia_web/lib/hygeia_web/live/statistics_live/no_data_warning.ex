defmodule HygeiaWeb.StatisticsLive.NoDataWarning do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop title, :string, default: nil

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~F"""
    <div class="card justify-content-center align-items-center p-5">
      <h5 :if={@title != nil} class="card-title mb-5 text-muted">{@title}</h5>
      <p class="alert alert-warning m-0 d-flex text-warning align-items-center">
        <span class="h3 oi oi-warning mr-2 mb-0" aria-hidden="true" />
        {gettext("No data to display")}
      </p>
    </div>
    """
  end
end
