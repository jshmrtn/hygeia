defmodule HygeiaWeb.AffiliationLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import Ecto.Query

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.Repo
  alias Surface.Components.Context
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  data organisation, :map
  data divisions, :list
  data affiliations, :list
  data pagination, :map
  data pagination_params, :list, default: []
  data page_title, :string
  data filters, :map, default: %{}

  @impl Phoenix.LiveView
  def handle_params(%{"organisation_id" => organisation_id} = params, _uri, socket) do
    organisation = OrganisationContext.get_organisation!(organisation_id)

    socket =
      if authorized?(Affiliation, :list, get_auth(socket), organisation: organisation) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "affiliations")

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
          divisions: Repo.preload(organisation, :divisions).divisions,
          page_title:
            "#{gettext("Affiliations")} - #{organisation.name} - #{gettext("Organisation")}"
        )
        |> list_affiliations()
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    {:noreply, socket |> assign(filters: params["filter"] || %{}) |> list_affiliations()}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Affiliation{}, _version}, socket) do
    {:noreply, list_affiliations(socket)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @allowed_filter_fields %{
    "division_uuid" => :division_uuid,
    "active_cases" => :active_cases
  }

  defp list_affiliations(socket) do
    %Paginator.Page{entries: entries, metadata: metadata} =
      socket.assigns.filters
      |> Enum.map(fn {key, value} ->
        {@allowed_filter_fields[key], value}
      end)
      |> Enum.reject(&match?({nil, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Enum.reject(&match?({_key, []}, &1))
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({_key, ""}, &1))
      |> Enum.reduce(
        from(affiliation in Ecto.assoc(socket.assigns.organisation, :affiliations),
          join: person in assoc(affiliation, :person),
          as: :person,
          preload: [person: {person, [:tenant]}, division: []],
          order_by: [person.first_name, person.last_name]
        ),
        fn
          {:division_uuid, "none"}, query ->
            where(query, [affiliation], is_nil(affiliation.division_uuid))

          {:division_uuid, value}, query ->
            where(query, [affiliation], affiliation.division_uuid == ^value)

          {:active_cases, "false"}, query ->
            query

          {:active_cases, "true"}, query ->
            query
            |> join(:left, [affiliation], case in Case,
              on: affiliation.person_uuid == case.person_uuid,
              as: :case
            )
            |> join(:left, [affiliation, case: case], phase in fragment("UNNEST(?)", case.phases),
              as: :phase
            )
            |> where(
              [affiliation, case: case, phase: phase],
              fragment("?->'quarantine_order'", phase) == fragment("TO_JSONB(?)", true) and
                fragment(
                  "? BETWEEN ? AND ?",
                  fragment("CURRENT_DATE"),
                  fragment("(?->>'start')::date", phase),
                  fragment("(?->>'end')::date", phase)
                )
            )
        end
      )
      |> Repo.paginate(
        Keyword.merge(socket.assigns.pagination_params,
          cursor_fields: [{{:person, :first_name}, :asc}, {{:person, :last_name}, :asc}]
        )
      )

    assign(socket,
      pagination: metadata,
      affiliations: entries
    )
  rescue
    ArgumentError -> reraise HygeiaWeb.InvalidPaginationParamsError, __STACKTRACE__
  end

  defp person_display_name(%Person{last_name: nil, first_name: first_name} = _person) do
    first_name
  end

  defp person_display_name(%Person{last_name: last_name, first_name: first_name} = _person) do
    "#{first_name} #{last_name}"
  end
end
