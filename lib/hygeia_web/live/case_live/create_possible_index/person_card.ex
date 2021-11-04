defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard do
  @moduledoc false

  use HygeiaWeb, :surface_component

  import Ecto.Changeset

  prop person_changeset, :any, default: nil

  slot header
  slot feature
  slot left
  slot right
  slot bottom
  slot error

  @spec show_field(map :: map(), key :: atom(), default :: String.t()) :: String.t()
  def show_field(map, key, default \\ "")

  def show_field(nil, _key, text) do
    text
  end

  def show_field(map, key, default) do
    Map.get(map, key, default)
  end
end
