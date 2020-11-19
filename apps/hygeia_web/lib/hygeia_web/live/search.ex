defmodule HygeiaWeb.Search do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Hygeia.UserContext
  alias Surface.Components.Form.SearchInput
  alias Surface.Components.Link

  data open, :boolean, default: false
  data query, :string, default: ""
  data results, :map, default: %{}

  @impl Phoenix.LiveComponent
  def handle_event("open", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  def handle_event("search", %{"query" => query} = _params, socket) do
    {:noreply, search_results(socket, query)}
  end

  defp search_results(socket, "") do
    assign(socket, results: %{}, query: "", task: nil)
  end

  defp search_results(socket, query) do
    results =
      %{
        person:
          if authorized?(CaseContext.Person, :list, get_auth(socket)) do
            fn ->
              socket.assigns.query
              |> CaseContext.fulltext_person_search()
              |> Enum.map(&{&1.uuid, &1})
            end
          end,
        case:
          if authorized?(CaseContext.Case, :list, get_auth(socket)) do
            fn ->
              socket.assigns.query
              |> CaseContext.fulltext_case_search()
              |> Repo.preload(:person)
              |> Enum.map(&{&1.uuid, &1})
            end
          end,
        organisation:
          if authorized?(OrganisationContext.Organisation, :list, get_auth(socket)) do
            fn ->
              socket.assigns.query
              |> OrganisationContext.fulltext_organisation_search()
              |> Enum.map(&{&1.uuid, &1.name})
            end
          end,
        user:
          if authorized?(UserContext.User, :list, get_auth(socket)) do
            fn ->
              socket.assigns.query
              |> UserContext.fulltext_user_search()
              |> Enum.map(&{&1.uuid, &1.display_name})
            end
          end
      }
      |> Enum.reject(&match?({_key, nil}, &1))
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
