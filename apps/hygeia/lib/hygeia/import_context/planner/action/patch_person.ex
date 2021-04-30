defmodule Hygeia.ImportContext.Planner.Action.PatchPerson do
  @moduledoc """
  Patch Person
  """

  @type t :: %__MODULE__{person_attrs: map}

  defstruct [:person_attrs]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.CaseContext.Person
    alias Hygeia.ImportContext.Planner.Action.PatchPerson

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %PatchPerson{person_attrs: person_attrs},
          %{person_changeset: person_changeset},
          _row
        ) do
      # TODO: Phone / EMail
      {:ok, %{person_changeset: Person.changeset(person_changeset, person_attrs)}}
    end
  end
end
