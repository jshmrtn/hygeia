defmodule Hygeia.ImportContext.Planner.Action.ChooseTenant do
  @moduledoc """
  Choose tenant
  """

  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{tenant: Tenant.t()}

  defstruct [:tenant]

  defimpl Hygeia.ImportContext.Planner.Action do
    alias Hygeia.ImportContext.Planner.Action.ChooseTenant

    @impl Hygeia.ImportContext.Planner.Action
    def execute(%ChooseTenant{tenant: tenant}, _preceding_results, _row),
      do: {:ok, %{tenant: tenant}}
  end
end
