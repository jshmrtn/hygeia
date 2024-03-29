defmodule HygeiaWeb.AutoTracingLive.Visits do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  import Ecto.Query
  import HygeiaWeb.Helpers.AutoTracing, only: [get_next_step_route: 1]

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.OrganisationVisit
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.Repo
  alias Phoenix.LiveView.Socket
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput

  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :has_visited, :boolean
    embeds_many :organisation_visits, OrganisationVisit, on_replace: :delete
  end

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [:affiliations], auto_tracing: [], visits: [:affiliation])

    socket =
      cond do
        Case.closed?(case) ->
          raise HygeiaWeb.AutoTracingLive.AutoTracing.CaseClosedError, case_uuid: case.uuid

        !authorized?(case, :auto_tracing, get_auth(socket)) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
              )
          )

        !AutoTracing.step_available?(case.auto_tracing, :visits) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          visits =
            Enum.map(
              case.visits,
              &%OrganisationVisit{
                uuid: Ecto.UUID.generate(),
                is_occupied: not is_nil(&1.affiliation),
                visit_reason: &1.reason,
                other_reason: &1.other_reason,
                visited_at: &1.last_visit_at,
                not_found: if(&1.unknown_organisation, do: true, else: false),
                organisation_uuid: &1.organisation_uuid,
                unknown_organisation: &1.unknown_organisation,
                division_not_found: if(&1.unknown_division, do: true, else: false),
                known_division_uuid: &1.division_uuid,
                unknown_division: &1.unknown_division
              }
            )

          step = %__MODULE__{
            has_visited:
              cond do
                Enum.any?(visits) -> true
                is_nil(case.auto_tracing.scholar) -> nil
                case.auto_tracing.scholar and Enum.empty?(visits) -> nil
                true -> false
              end,
            organisation_visits: visits
          }

          assign(socket,
            step: step,
            changeset: %Ecto.Changeset{changeset(step) | action: :validate},
            case: case,
            person: case.person,
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "add_organisation_visit",
        _params,
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Changeset{
         changeset(
           step,
           changeset_add_to_params(changeset, :organisation_visits, %{
             uuid: Ecto.UUID.generate()
           })
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_organisation_visit",
        %{"value" => organisation_visit_uuid},
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_remove_from_params_by_id(changeset, :organisation_visits, %{
             uuid: organisation_visit_uuid
           })
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_school",
        %{"subject" => school_uuid} = params,
        %{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_update_params_by_id(
             changeset,
             :organisation_visits,
             %{uuid: school_uuid},
             &Map.put(&1, "organisation_uuid", params["uuid"])
           )
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_school_division",
        %{"subject" => school_uuid} = params,
        %{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_update_params_by_id(
             changeset,
             :organisation_visits,
             %{uuid: school_uuid},
             &Map.put(&1, "known_division_uuid", params["uuid"])
           )
         )
         | action: :validate
       }
     )}
  end

  def handle_event("validate", %{"visits" => params}, socket) do
    params = Map.put_new(params, "organisation_visits", [])

    {:noreply,
     assign(socket,
       changeset: %Changeset{changeset(socket.assigns.step, params) | action: :validate}
     )}
  end

  def handle_event(
        "advance",
        _params,
        %Socket{
          assigns: %{case: case, person: person, changeset: changeset, auto_tracing: auto_tracing}
        } = socket
      ) do
    socket =
      changeset
      |> apply_action(:compute)
      |> case do
        {:error, changeset} ->
          assign(socket, changeset: changeset)

        {:ok, %__MODULE__{has_visited: has_visited} = step} ->
          person_changeset =
            person
            |> CaseContext.change_person()
            |> add_visited_affiliations_to_person(step)

          {:ok, _person} = CaseContext.update_person(person_changeset)

          case_changeset =
            case
            |> CaseContext.change_case()
            |> add_visits_to_case(step)

          {:ok, _case} = CaseContext.update_case(case_changeset)

          auto_tracing_changeset =
            auto_tracing
            |> AutoTracingContext.change_auto_tracing()
            |> put_change(:scholar, has_visited)

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          {:ok, auto_tracing} =
            if auto_tracing.scholar do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(auto_tracing, :school_related)
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :school_related)
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :visits)

          push_redirect(socket,
            to: get_next_step_route(:visits).(socket, socket.assigns.auto_tracing.case_uuid)
          )
      end

    {:noreply, socket}
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:has_visited])
    |> validate_organisation_visit()
    |> validate_required([:has_visited])
  end

  defp validate_organisation_visit(changeset) do
    changeset
    |> fetch_field!(:has_visited)
    |> case do
      true ->
        cast_embed(changeset, :organisation_visits,
          required: true,
          required_message:
            gettext(
              "please add at least one educational institution that you visited during the period in consideration"
            )
        )

      _else ->
        put_embed(changeset, :organisation_visits, [])
    end
  end

  defp add_visits_to_case(changeset, %__MODULE__{
         organisation_visits: organisation_visits
       }) do
    visits =
      Enum.map(
        organisation_visits,
        &%Visit{
          uuid: &1.uuid,
          reason: &1.visit_reason,
          other_reason: &1.other_reason,
          last_visit_at: &1.visited_at,
          organisation_uuid: &1.organisation_uuid,
          unknown_organisation: &1.unknown_organisation,
          division_uuid: &1.known_division_uuid,
          unknown_division: filter_unknown_division(&1.unknown_division)
        }
      )

    put_assoc(
      changeset,
      :visits,
      visits
    )
  end

  defp add_visited_affiliations_to_person(changeset, %__MODULE__{
         organisation_visits: organisation_visits
       }) do
    new_affiliations =
      organisation_visits
      |> Enum.filter(& &1.is_occupied)
      |> Enum.map(
        &%Affiliation{
          uuid: Ecto.UUID.generate(),
          kind: visit_reason_to_kind(&1.visit_reason),
          organisation_uuid: &1.organisation_uuid,
          unknown_organisation: &1.unknown_organisation,
          related_visit_uuid: &1.uuid,
          division_uuid: &1.known_division_uuid,
          unknown_division: filter_unknown_division(&1.unknown_division)
        }
      )

    put_assoc(
      changeset,
      :affiliations,
      fetch_field!(changeset, :affiliations) ++ new_affiliations
    )
  end

  defp visit_reason_to_kind(:student), do: :scholar

  defp visit_reason_to_kind(visit_reason) when visit_reason in [:professor, :employee],
    do: :employee

  defp filter_unknown_division(%Entity{
         name: nil,
         address: %Address{address: nil, zip: nil, place: nil, subdivision: nil, country: "CH"}
       }),
       do: nil

  defp filter_unknown_division(%Entity{
         name: nil,
         address: nil
       }),
       do: nil

  defp filter_unknown_division(division), do: division
end
