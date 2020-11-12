defmodule HygeiaWeb.Search do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Surface.Components.Form.SearchInput
  alias Surface.Components.Link

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, search_results(socket, "")}
  end

  @impl Phoenix.LiveComponent
  def handle_event("search", %{"query" => query} = _params, socket) do
    {:noreply, search_results(socket, query)}
  end

  defp search_results(socket, "") do
    assign(socket, results: %{}, query: "", task: nil)
  end

  defp search_results(socket, query) do
    results =
      %{
        person: fn ->
          socket.assigns.query
          |> CaseContext.fulltext_person_search()
          |> Enum.map(&{&1.uuid, &1})
        end,
        case: fn ->
          socket.assigns.query
          |> CaseContext.fulltext_case_search()
          |> Repo.preload(:person)
          |> Enum.map(&{&1.uuid, &1})
        end,
        organisation: fn ->
          socket.assigns.query
          |> OrganisationContext.fulltext_organisation_search()
          |> Enum.map(&{&1.uuid, &1.name})
        end,
        user: fn ->
          socket.assigns.query
          |> UserContext.fulltext_user_search()
          |> Enum.map(&{&1.uuid, &1.display_name})
        end
      }
      |> Enum.map(fn {key, callback} ->
        Task.async(fn ->
          {key, callback.()}
        end)
      end)
      |> Enum.map(&Task.await(&1))
      |> Enum.reject(&match?({_key, []}, &1))
      |> Map.new()

    assign(socket, query: query, results: results)
  end
end
