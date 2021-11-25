defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.Suggestions do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople.Search
  alias Surface.Components.Context

  prop person, :map, required: true
  prop suggestions, :list, required: true

  prop person_selected, :event
  prop case_selected, :event

  defp get_contact_methods(person, type) do
    person.contact_methods
    |> Enum.filter(&(&1.type == type))
    |> Enum.map_join(", ", & &1.value)
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
