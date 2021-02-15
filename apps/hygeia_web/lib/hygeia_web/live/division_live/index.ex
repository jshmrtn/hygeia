defmodule HygeiaWeb.DivisionLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.Repo
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  data organisation, :map
  data divisions, :list
  data pagination, :map
  data pagination_params, :list, default: []
  data page_title, :string

  @impl Phoenix.LiveView
  def handle_params(%{"organisation_id" => organisation_id} = params, _uri, socket) do
    organisation = OrganisationContext.get_organisation!(organisation_id)

    socket =
      if authorized?(Division, :list, get_auth(socket), organisation: organisation) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "divisions")

        pagination_params =
          case params do
            %{"cursor" => cursor, "cursor_direction" => "after"} -> [after: cursor]
            %{"cursor" => cursor, "cursor_direction" => "before"} -> [before: cursor]
            _other -> []
          end

        socket
        |> assign(
          pagination_params: pagination_params,
          organisation: organisation,
          page_title:
            "#{gettext("Divisions")} - #{organisation.name} - #{gettext("Organisation")}"
        )
        |> list_divisions()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    division = OrganisationContext.get_division!(id)

    true = authorized?(division, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_division(division)

    {:noreply, list_divisions(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Division{}, _version}, socket) do
    {:noreply, list_divisions(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_divisions(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      Repo.paginate(
        Ecto.assoc(socket.assigns.organisation, :divisions),
        Keyword.merge(socket.assigns.pagination_params, cursor_fields: [title: :asc])
      )

    assign(socket,
      pagination: metadata,
      divisions: entries
    )
  end
end
