defmodule Hygeia.ImportContext.Planner.Action.PatchTests do
  @moduledoc """
  Patch / Append Test
  """

  @type t :: %__MODULE__{action: :append | :patch, test_attrs: map, reference: String.t()}

  defstruct [:action, :test_attrs, :reference]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Ecto.Changeset
    alias Hygeia.CaseContext.Test
    alias Hygeia.ImportContext.Planner.Action.PatchTests
    alias Hygeia.MutationContext
    alias Hygeia.MutationContext.Mutation

    require Logger

    @impl Hygeia.ImportContext.Planner.Action
    def execute(
          %PatchTests{action: :append, test_attrs: test_attrs},
          %{case_changeset: case_changeset},
          _row
        ) do
      fallback_tests =
        case_changeset
        |> Changeset.fetch_field!(:tests)
        |> Enum.map(&Changeset.change/1)

      test_attrs =
        if is_nil(test_attrs[:mutation]) do
          test_attrs
        else
          Map.put(
            test_attrs,
            :mutation_uuid,
            case MutationContext.get_mutation_by_ism_code(test_attrs.mutation.ism_code) do
              %Mutation{uuid: uuid} ->
                uuid

              nil ->
                message = "No mutations found for #{inspect(test_attrs.mutation)}"
                Logger.warn(message)
                Sentry.capture_message(message)

                nil
            end
          )
        end

      tests =
        Changeset.get_change(case_changeset, :tests, fallback_tests) ++
          [Test.changeset(%Test{}, test_attrs)]

      {:ok, %{case_changeset: Changeset.put_assoc(case_changeset, :tests, tests)}}
    end

    def execute(
          %PatchTests{action: :patch, test_attrs: test_attrs, reference: reference},
          %{case_changeset: case_changeset},
          _row
        ) do
      fallback_tests =
        case_changeset
        |> Changeset.fetch_field!(:tests)
        |> Enum.map(&Changeset.change/1)

      tests =
        case_changeset
        |> Changeset.get_change(:tests, fallback_tests)
        |> Enum.map(fn test_changeset ->
          if Changeset.fetch_field!(test_changeset, :reference) == reference do
            Test.changeset(test_changeset, test_attrs)
          else
            test_changeset
          end
        end)

      {:ok, %{case_changeset: Changeset.put_assoc(case_changeset, :tests, tests)}}
    end
  end
end
