defmodule HygeiaWeb.UriActiveContext do
  @moduledoc false

  use Surface.Component

  slot default, props: [:active, :to], required: true

  prop to, :string, required: true
  prop opts, :keyword, default: [active: :exact]

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <Context get={{ HygeiaWeb, uri: uri }}>
      <slot :props={{ active: is_active(@to, uri, @opts), to: @to }} />
    </Context>
    """
  end

  defp is_active(to, uri, opts) do
    %URI{path: path, query: query} = URI.parse(uri)

    PhoenixActiveLink.active_path?(
      %{request_path: path, query_string: query, private: %{}},
      opts ++ [to: to]
    )
  end
end
