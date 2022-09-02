defmodule HygeiaWeb.UriActiveContext do
  @moduledoc false

  use Surface.Component

  slot default, arg: %{active: :boolean, to: :string}, required: true

  prop to, :string, required: true
  prop opts, :keyword, default: [active: :exact]

  prop uri, :string, from_context: {HygeiaWeb, :uri}

  @impl Surface.Component
  def render(assigns) do
    ~F"""
    <#slot {@default, active: is_active(@to, @uri, @opts), to: @to} />
    """
  end

  defp is_active(to, uri, opts) do
    %URI{path: path, query: query} = URI.parse(uri)

    PhoenixActiveLink.active_path?(
      %{request_path: path || "/", query_string: query, private: %{}},
      opts ++ [to: to]
    )
  end
end
