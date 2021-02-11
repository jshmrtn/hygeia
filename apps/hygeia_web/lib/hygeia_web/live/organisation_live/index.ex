defmodule HygeiaWeb.OrganisationLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Surface.Components.Context
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext

  alias Surface.Components.Form.Select
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Organisation, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "organisations")

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        socket
        |> assign(pagination_params: pagination_params, filters: %{})
        |> list_organisations
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    organisation = OrganisationContext.get_organisation!(id)

    true = authorized?(organisation, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_organisation(organisation)

    {:noreply, list_organisations(socket)}
  end

  def handle_event("filter", params, socket) do
    {:noreply, socket |> assign(filters: params["filter"] || %{}) |> list_organisations()}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Organisation{}, _version}, socket) do
    {:noreply, list_organisations(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @allowed_filter_fields %{
    "country" => :country,
    "subdivision" => :subdivision
  }

  defp list_organisations(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.filters
      |> Enum.map(fn {key, value} ->
        {@allowed_filter_fields[key], value}
      end)
      |> Enum.reject(&match?({nil, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({_key, []}, &1))
      |> Enum.reject(&match?({_key, ""}, &1))
      |> Enum.reduce(OrganisationContext.list_organisations_query(), fn
        {:country, value}, query ->
          where(query, [organisation], fragment("?->'country'", organisation.address) == ^value)

        {:subdivision, value}, query ->
          where(
            query,
            [organisation],
            fragment("?->'subdivision'", organisation.address) == ^value
          )
      end)
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [name: :asc])
      )

    assign(socket,
      pagination: metadata,
      organisations: entries
    )
  end
end
