defmodule HygeiaWeb.PersonLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Phase
  alias Hygeia.Repo
  alias Surface.Components.LivePatch

  # Changeset or actual Person
  prop person, :map, required: true
  prop active_case, :map, default: nil

  @impl Phoenix.LiveComponent
  def update(
        %{person: %Changeset{data: data} = changeset, active_case: active_case} = _assings,
        socket
      ) do
    {:ok,
     assign(socket,
       person_display_name: person_display_name(changeset),
       person: Repo.preload(data, :cases),
       active_case: active_case
     )}
  end

  def update(%{person: %Person{} = person, active_case: active_case} = _assings, socket) do
    {:ok,
     assign(socket,
       person_display_name: person_display_name(person),
       person: Repo.preload(person, :cases),
       active_case: active_case
     )}
  end

  defp person_display_name(%Changeset{} = changeset) do
    case Changeset.get_field(changeset, :last_name) do
      nil -> Changeset.get_field(changeset, :first_name)
      other -> "#{Changeset.get_field(changeset, :first_name)} #{other}"
    end
  end

  defp person_display_name(%Person{last_name: nil, first_name: first_name} = _person) do
    first_name
  end

  defp person_display_name(%Person{last_name: last_name, first_name: first_name} = _person) do
    "#{first_name} #{last_name}"
  end

  defp case_display_name(%Case{phases: [%Phase{start: start_date} | _] = phases}) do
    %Phase{end: end_date} = last_phase = List.last(phases)

    "#{case_phase_type_translation(last_phase)} (#{
      Cldr.Interval.to_string!(Date.range(start_date, end_date), HygeiaWeb.Cldr)
    })"
  end

  defp case_phase_type_translation(%Phase{type: :possible_index}), do: gettext("Possible Index")
  defp case_phase_type_translation(%Phase{type: :index}), do: gettext("Index")
end
