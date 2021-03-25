defmodule HygeiaWeb.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect
end
