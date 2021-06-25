defmodule Hygeia.ImportContext.Planner.Action.PatchExternalReferences do
  @moduledoc """
  Patch External References
  """

  alias Ecto.Changeset
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.ExternalReference.Type
  alias Hygeia.CaseContext.Person

  @type t :: %__MODULE__{references: [{:case | :person, Type.t(), String.t()}]}

  defstruct [:references]

  @doc false
  @spec append_external_reference(
          changeset :: Changeset.t(resource),
          type :: Type.t(),
          value :: String.t()
        ) :: Changeset.t(resource)
        when resource: Case.t() | Person.t()
  def append_external_reference(changeset, type, value) do
    fallback_external_references =
      changeset
      |> Changeset.fetch_field!(:external_references)
      |> Enum.map(&Changeset.change/1)

    external_references =
      Changeset.get_change(changeset, :external_references, fallback_external_references)

    external_references =
      if Enum.any?(external_references, &(Changeset.fetch_field!(&1, :type) == type)) do
        external_references
      else
        external_references ++
          [
            ExternalReference.changeset(%ExternalReference{}, %{
              type: type,
              value: to_string(value)
            })
          ]
      end

    Changeset.put_embed(changeset, :external_references, external_references)
  end

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.ImportContext.Planner.Action.PatchExternalReferences

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %PatchExternalReferences{references: references},
          %{case_changeset: case_changeset, person_changeset: person_changeset},
          _row
        ) do
      {case_changeset, person_changeset} =
        Enum.reduce(references, {case_changeset, person_changeset}, fn
          {:case, type, value}, {case_changeset, person_changeset} ->
            {PatchExternalReferences.append_external_reference(case_changeset, type, value),
             person_changeset}

          {:person, type, value}, {case_changeset, person_changeset} ->
            {case_changeset,
             PatchExternalReferences.append_external_reference(person_changeset, type, value)}
        end)

      {:ok, %{case_changeset: case_changeset, person_changeset: person_changeset}}
    end
  end
end
