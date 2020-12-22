defmodule HygeiaWeb.Search do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Surface.Components.Form.SearchInput
  alias Surface.Components.Link

  data open, :boolean, default: false
  data query, :string, default: ""
  data results, :map, default: %{}
  data pending_search, :any, default: nil

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, tenants: TenantContext.list_tenants())}
  end

  @impl Phoenix.LiveComponent
  def update(%{append_result: {key, result}} = assigns, socket) do
    socket = assign(socket, Map.drop(assigns, [:append_result]))
    socket = assign(socket, results: Map.put(socket.assigns.results, key, result))
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  def handle_event("search", %{"query" => query} = _params, socket) do
    {:noreply, search_results(socket, query)}
  end

  defp search_results(socket, "") do
    if socket.assigns.pending_search do
      Task.shutdown(socket.assigns.pending_search, :brutal_kill)
    end

    assign(socket, results: %{}, query: "", pending_search: nil)
  end

  defp search_results(socket, query) do
    if socket.assigns.pending_search do
      Task.shutdown(socket.assigns.pending_search, :brutal_kill)
    end

    pid = self()

    task =
      Task.async(fn ->
        query
        |> search_fns(socket)
        |> Enum.reject(&match?({_key, nil}, &1))
        |> Enum.map(fn {key, callback} ->
          Task.async(fn -> run_search(key, callback, pid, socket) end)
        end)
        |> Enum.each(&Task.await/1)

        send_update(pid, __MODULE__, id: socket.assigns.id, pending_search: nil)
      end)

    assign(socket, query: query, results: %{}, pending_search: task)
  end

  defp run_search(key, callback, pid, socket) do
    case callback.() do
      nil ->
        :ok

      [] ->
        :ok

      [_ | _] = results ->
        send_update(pid, __MODULE__, id: socket.assigns.id, append_result: {key, results})

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
