defmodule HygeiaWeb.PersonLive.Vaccination do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset

  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.TextInput

  prop disabled, :boolean, default: false
  prop changeset, :map
  prop person, :map

  prop add_event, :event
  prop remove_event, :event

  defp at_least_two_dates(changeset) do
    changeset
    |> fetch_field!(:vaccination)
    |> case do
      nil ->
        false

      vaccination ->
        vaccination
        |> Map.get(:jab_dates, [])
        |> Enum.reject(&is_nil/1)
        |> length() >= 2
    end
  end

  defp fill_dates(dates) do
    case length(dates) do
      0 -> [nil, nil]
      1 -> dates ++ [nil]
      _else -> dates
    end
  end
end
