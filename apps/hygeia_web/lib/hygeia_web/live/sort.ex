defmodule HygeiaWeb.Sort do
  @moduledoc """
  Sort Table Header Component
  """

  use HygeiaWeb, :surface_live_component

  slot default, props: [:asc?, :desc?, :active, :sort_params]

  prop params, :list, required: true
  prop current_params, :list, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <span class="sort-row-header">
      <slot :props={{
        asc?: is_asc?(@params, @current_params),
        desc?: is_desc?(@params, @current_params),
        active: is_asc?(@params, @current_params) or is_desc?(@params, @current_params),
        sort_params:
          if(is_asc?(@params, @current_params),
            do: Enum.map(@params, &"desc_#{&1}"),
            else: Enum.map(@params, &"asc_#{&1}")
          )
      }} />
      <span :if={{ is_asc?(@params, @current_params) }} class="oi oi-sort-descending" />
      <span :if={{ is_desc?(@params, @current_params) }} class="oi oi-sort-ascending" />
    </span>
    """
  end

  defp is_asc?(params, current_params) do
    Enum.map(params, &"asc_#{&1}") == current_params
  end

  defp is_desc?(params, current_params) do
    Enum.map(params, &"desc_#{&1}") == current_params
  end
end
