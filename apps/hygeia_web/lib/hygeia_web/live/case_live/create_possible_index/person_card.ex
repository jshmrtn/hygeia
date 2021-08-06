defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard do
  @moduledoc false

  use HygeiaWeb, :surface_component

  prop person, :any, default: nil

  slot header
  slot feature
  slot left
  slot right
  slot bottom

  def show_field(nil, _, default \\ "") do
    ""
  end

  def show_field(map, key, default) do
    Map.get(map, key, default)
  end
end
