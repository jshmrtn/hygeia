defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Phase
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true

  @impl Phoenix.LiveComponent
  def handle_event(
        "convert_to_index",
        _params,
        %{assigns: %{case: %Case{phases: phases} = case}} = socket
      ) do
    true = authorized?(case, :update, get_auth(socket))

    index_last = length(phases) - 1

    phase_args =
      phases
      |> Enum.with_index()
      |> Enum.map(fn
        {phase, ^index_last} ->
          %{uuid: phase.uuid, details: %{end_reason: :converted_to_index}, end: Date.utc_today()}

        {phase, _other_index} ->
          %{uuid: phase.uuid}
      end)
      |> Kernel.++([%{start: Date.utc_today(), details: %{__type__: :index}}])

    {:ok, case} = CaseContext.update_case(case, %{phases: phase_args})

    {:noreply,
     socket
     |> push_redirect(to: Routes.case_base_data_path(socket, :show, case))
     |> put_flash(:info, gettext("Created Index Phase."))}
  end
end
