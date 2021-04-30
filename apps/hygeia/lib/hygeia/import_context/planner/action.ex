defprotocol Hygeia.ImportContext.Planner.Action do
  alias Hygeia.ImportContext.Planner
  alias Hygeia.ImportContext.Row

  @type t ::
          __MODULE__.ChooseTenant.t()
          | __MODULE__.PatchAssignee.t()
          | __MODULE__.PatchExternalReferences.t()
          | __MODULE__.PatchPerson.t()
          | __MODULE__.PatchPhaseDeath.t()
          | __MODULE__.PatchPhases.t()
          | __MODULE__.PatchStatus.t()
          | __MODULE__.PatchTests.t()
          | __MODULE__.Save.t()
          | __MODULE__.SelectCase.t()

  @doc "Ececute Action"
  @spec execute(
          action :: t,
          preceeding_results :: Planner.action_execute_meta(),
          row :: Row.t()
        ) :: {:ok, Planner.action_execute_meta()} | {:error, term}
  def execute(action, preceding_results, row)
end
