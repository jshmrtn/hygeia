defmodule Hygeia.ImportContext.Planner.Action.SelectCase do
  @moduledoc """
  Select / Create Case Action
  """

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  @type existing_case :: %__MODULE__{
          case: Case.t(),
          person: Person.t()
        }
  @type existing_person :: %__MODULE__{
          case: nil,
          person: Person.t()
        }
  @type create :: %__MODULE__{
          case: nil,
          person: nil
        }

  @type t :: existing_case | existing_person | create

  defstruct [:case, :person]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext
    alias Hygeia.CaseContext.Case
    alias Hygeia.CaseContext.Person
    alias Hygeia.ImportContext.Planner.Action.SelectCase

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%SelectCase{case: nil, person: nil}, %{tenant: tenant}, _row) do
      person = nil
      person_changeset = Changeset.change(%Person{}, %{tenant_uuid: tenant.uuid})
      case = nil
      case_changeset = Changeset.change(%Case{}, %{tenant_uuid: tenant.uuid})

      {:ok,
       %{
         person: person,
         person_changeset: person_changeset,
         case: case,
         case_changeset: case_changeset
       }}
    end

    def execute(%SelectCase{case: nil, person: %Person{} = person}, %{tenant: tenant}, _row),
      do:
        {:ok,
         %{
           person: person,
           person_changeset: CaseContext.change_person(person),
           case: nil,
           case_changeset:
             Changeset.change(%Case{}, %{tenant_uuid: tenant.uuid, person_uuid: person.uuid})
         }}

    def execute(
          %SelectCase{case: %Case{} = case, person: %Person{} = person},
          _preceding_results,
          _row
        ),
        do:
          {:ok,
           %{
             person: person,
             person_changeset: CaseContext.change_person(person),
             case: case,
             case_changeset: CaseContext.change_case(case)
           }}
  end
end
