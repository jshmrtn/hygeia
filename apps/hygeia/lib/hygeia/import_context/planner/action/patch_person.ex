defmodule Hygeia.ImportContext.Planner.Action.PatchPerson do
  @moduledoc """
  Patch Person
  """

  @type t :: %__MODULE__{person_attrs: map}

  defstruct [:person_attrs]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.CaseContext.Person
    alias Hygeia.CaseContext.Person.ContactMethod
    alias Hygeia.ImportContext.Planner.Action.PatchPerson

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %PatchPerson{person_attrs: person_attrs},
          %{person_changeset: person_changeset},
          _row
        ) do
      person_changeset = Person.changeset(person_changeset, person_attrs)

      existing_values =
        person_changeset
        |> Ecto.Changeset.fetch_field!(:contact_methods)
        |> Enum.map(& &1.value)

      person_changeset =
        [:mobile, :landline, :email]
        |> Enum.map(&{&1, person_attrs[&1]})
        |> Enum.reject(&match?({_type, nil}, &1))
        |> Enum.reject(&(elem(&1, 1) in existing_values))
        |> Enum.map(fn {type, value} ->
          ContactMethod.changeset(%ContactMethod{}, %{type: type, value: value})
        end)
        |> Enum.reduce(person_changeset, fn new_contact_method, acc ->
          Ecto.Changeset.put_embed(
            acc,
            :contact_methods,
            Ecto.Changeset.fetch_field!(acc, :contact_methods) ++ [new_contact_method]
          )
        end)

      {:ok, %{person_changeset: person_changeset}}
    end
  end
end
