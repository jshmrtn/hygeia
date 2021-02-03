defmodule HygeiaWeb.Pagination do
  @moduledoc """
  Pagination Component
  """

  use HygeiaWeb, :surface_live_component

  slot default, props: [:cursor_direction, :cursor, :text]

  prop pagination, :map, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <ul class="pagination justify-content-center">
      <li class="page-item" :if={{ not is_nil(@pagination.before) }}>
        <slot :props={{ cursor_direction: "before", cursor: @pagination.before, text: gettext("Previous") }} />
      </li>
      <li class="page-item disabled" :if={{ is_nil(@pagination.before) }}>
        <span class="page-link">{{ gettext("Previous") }}</span>
      </li>
      <li class="page-item disabled">
        <span class="page-link">
          {{ gettext("Showing %{count} of %{total} entries",
            count: min(@pagination.limit, @pagination.total_count),
            total: @pagination.total_count
          ) }}
        </span>
      </li>
      <li class="page-item" :if={{ not is_nil(@pagination.after) }}>
        <slot :props={{ cursor_direction: "after", cursor: @pagination.after, text: gettext("Next") }} />
      </li>
      <li class="page-item disabled" :if={{ is_nil(@pagination.after) }}>
        <span class="page-link">{{ gettext("Next") }}</span>
      </li>
    </ul>
    """
  end
end
