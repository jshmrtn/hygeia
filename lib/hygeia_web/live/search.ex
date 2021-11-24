defmodule HygeiaWeb.Search do
  @moduledoc false

  use HygeiaWeb, :surface_view_bare

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Surface.Components.Form.SearchInput
  alias Surface.Components.Link

  data open, :boolean, default: false
  data tenants, :list, default: []
  data query, :string, default: ""
  data results, :map, default: %{}
  data pending_search, :any, default: nil
  data debouncer, :pid
  data debouncing, :boolean, default: false

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, debouncer} = Debounce.start_link({__MODULE__, :search, []}, :timer.seconds(1), [])
    {:ok, assign(socket, tenants: TenantContext.list_tenants(), debouncer: debouncer)}
  end

  @impl Phoenix.LiveView

  def handle_info({:start_search, task}, socket),
    do: {:noreply, assign(socket, pending_search: task, results: %{}, debouncing: false)}

  def handle_info(
        {:clear_pending_search, pid},
        %{assigns: %{pending_search: %Task{pid: pid}}} = socket
      ),
      do: {:noreply, assign(socket, pending_search: nil)}

  # Clear arrived too late
  def handle_info({:clear_pending_search, _pid}, socket), do: {:noreply, socket}

  def handle_info(
        {:append_result, {key, new_results}, pid},
        %{assigns: %{results: results_before, pending_search: %Task{pid: pid}}} = socket
      ),
      do: {:noreply, assign(socket, results: Map.put(results_before, key, new_results))}

  # Result arrived too late
  def handle_info({:append_result, {_key, _new_results}, _pid}, socket),
    do: {:noreply, socket}

  # TODO: Report to LiveView as Bug
  def handle_info({ref, msg}, socket) when is_reference(ref), do: handle_info(msg, socket)

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("open", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  def handle_event("search", %{"query" => query} = _params, socket) do
    Debounce.apply(socket.assigns.debouncer, [socket, self(), query])
    {:noreply, assign(socket, query: query, debouncing: true)}
  end

  @doc false
  @spec search(socket :: Phoenix.LiveView.Socket.t(), pid :: pid, query :: String.t()) :: :ok
  def search(socket, pid, query)

  def search(_socket, pid, "") do
    send(
      pid,
      {:start_search,
       Task.async(fn ->
         send(pid, {:clear_pending_search, pid})
       end)}
    )

    :ok
  end

  def search(socket, pid, query) do
    send(
      pid,
      {:start_search,
       Task.async(fn ->
         task_pid = self()

         query
         |> search_fns(socket)
         |> Enum.reject(&match?({_key, nil}, &1))
         |> Enum.map(fn {key, callback} ->
           Task.async(fn -> run_search(key, callback, pid, task_pid) end)
         end)
         |> Enum.each(&Task.await/1)

         send(pid, {:clear_pending_search, task_pid})
       end)}
    )

    :ok
  end

  defp run_search(key, callback, pid, task_pid) do
    case callback.() do
      nil ->
        :ok

      [] ->
        :ok

      [_ | _] = results ->
        send(pid, {:append_result, {key, results}, task_pid})

        :ok
    end
  end

  defp search_fns(query, socket) do
    %{
      person:
        if authorized?(CaseContext.Person, :list, get_auth(socket), tenant: :any) do
          tenants =
            Enum.filter(
              socket.assigns.tenants,
              &authorized?(CaseContext.Person, :list, get_auth(socket), tenant: &1)
            )

          fn ->
            from(case in CaseContext.fulltext_person_search_query(query),
              where: case.tenant_uuid in ^Enum.map(tenants, & &1.uuid)
            )
            |> Repo.all()
            |> Enum.map(&{&1.uuid, &1})
          end
        end,
      case:
        if authorized?(CaseContext.Case, :list, get_auth(socket), tenant: :any) do
          tenants =
            Enum.filter(
              socket.assigns.tenants,
              &authorized?(CaseContext.Case, :list, get_auth(socket), tenant: &1)
            )

          fn ->
            from(case in CaseContext.fulltext_case_search_query(query),
              where: case.tenant_uuid in ^Enum.map(tenants, & &1.uuid)
            )
            |> Repo.all()
            |> Repo.preload(:person)
            |> Enum.map(&{&1.uuid, &1})
          end
        end,
      organisation:
        if authorized?(OrganisationContext.Organisation, :list, get_auth(socket)) do
          fn ->
            query
            |> OrganisationContext.fulltext_organisation_search()
            |> Enum.map(&{&1.uuid, &1.name})
          end
        end,
      user:
        if authorized?(UserContext.User, :list, get_auth(socket)) do
          fn ->
            query
            |> UserContext.fulltext_user_search()
            |> Enum.map(&{&1.uuid, &1.display_name})
          end
        end
    }
  end
end
