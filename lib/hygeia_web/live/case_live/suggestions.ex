defmodule HygeiaWeb.CaseLive.Suggestions do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Ecto.Changeset
  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Empty
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Link

  prop person_changeset, :map, required: true
  prop show_empty, :boolean, default: false
  # Instead of a `new_selected`, use a submit button
  prop new_as_submit, :boolean, default: false
  prop subject, :any, default: nil

  prop new_selected, :event
  prop person_selected, :event
  prop case_selected, :event

  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop timezone, :string, from_context: {HygeiaWeb, :timezone}

  data suggestions, :list, default: []
  data person, :map
  data empty, :boolean, default: false

  @impl Phoenix.LiveComponent
  def preload(assigns_list) do
    person_uuids = assign_list_duplicate_people_uuids(assigns_list)
    people = load_people_by_uuid(person_uuids)

    Enum.map(assigns_list, fn %{person_changeset: person_changeset} = assigns ->
      suggestions =
        person_changeset
        |> Changeset.fetch_field!(:suspected_duplicates_uuid)
        |> case do
          nil ->
            []

          suspected_duplicates_uuid ->
            suspected_duplicates_uuid
            |> Enum.map(&people[&1])
            |> Enum.reject(&is_nil/1)
        end

      person =
        person_changeset
        |> Changeset.apply_changes()
        |> Repo.preload(tenant: [])

      empty =
        Empty.is_empty?(person_changeset, [:suspected_duplicates_uuid, :uuid, :human_readable_id])

      assigns
      |> Map.put(:suggestions, suggestions)
      |> Map.put(:person, person)
      |> Map.put(:empty, empty)
    end)
  end

  defp assign_list_duplicate_people_uuids(assigns_list) do
    Enum.flat_map(
      assigns_list,
      fn %{person_changeset: person_changeset} ->
        person_changeset
        |> Changeset.fetch_field!(:suspected_duplicates_uuid)
        |> case do
          nil -> []
          list -> list
        end
        |> Enum.slice(0..4)
      end
    )
  end

  defp load_people_by_uuid(uuids)
  defp load_people_by_uuid([]), do: %{}

  defp load_people_by_uuid(uuids) do
    from(person in Person,
      where: person.uuid in ^uuids,
      preload: [tenant: [], cases: [tenant: []]]
    )
    |> Repo.all()
    |> Map.new(&{&1.uuid, &1})
  end

  defp get_contact_methods(person, type) do
    person.contact_methods
    |> Enum.filter(&(&1.type == type))
    |> Enum.map_join(", ", & &1.value)
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)
end
