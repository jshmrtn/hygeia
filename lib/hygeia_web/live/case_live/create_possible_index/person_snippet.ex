defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.PersonSnippet do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Surface.Components.Link

  prop person, :map, required: true
end
