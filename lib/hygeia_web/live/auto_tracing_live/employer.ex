defmodule HygeiaWeb.AutoTracingLive.Employer do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  import Ecto.Query

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Occupation
  alias Hygeia.AutoTracingContext.AutoTracing.SchoolVisit
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :employed, :boolean
    field :scholar, :boolean
    embeds_many :school_visits, SchoolVisit, on_replace: :delete

    embeds_many :school_visit_occupations, Occupation, on_replace: :delete
    embeds_many :occupations, Occupation, on_replace: :delete
  end

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [:affiliations], auto_tracing: [])

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

        !AutoTracing.step_available?(case.auto_tracing, :employer) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          person_occupations =
            case.auto_tracing.occupations
            |> Enum.filter(&is_nil(&1.related_school_visit_uuid))
            |> Enum.map(
              &%Occupation{
                uuid: Ecto.UUID.generate(),
                kind: &1.kind,
                kind_other: &1.kind_other,
                known_organisation_uuid: &1.known_organisation_uuid,
                unknown_organisation: &1.unknown_organisation,
                related_school_visit_uuid: &1.related_school_visit_uuid,
                division_not_found: &1.division_not_found,
                known_division_uuid: &1.known_division_uuid,
                unknown_division: &1.unknown_division
              }
            )

          person_school_visit_occupations =
            case.person.affiliations
            |> Enum.filter(&(not is_nil(&1.related_school_visit_uuid)))

            |> Enum.map(
              &%Occupation{
                uuid: Ecto.UUID.generate(),
                kind: &1.kind,
                kind_other: &1.kind_other,
                known_organisation_uuid: &1.organisation_uuid,
                related_school_visit_uuid: &1.related_school_visit_uuid
              }
            )

          auto_tracing_school_visit_occupations =
            case.auto_tracing.occupations
            |> Enum.filter(&(not is_nil(&1.related_school_visit_uuid)))
            |> Enum.map(
              &%Occupation{
                uuid: Ecto.UUID.generate(),
                kind: &1.kind,
                kind_other: &1.kind_other,
                unknown_organisation: &1.unknown_organisation,
                related_school_visit_uuid: &1.related_school_visit_uuid
              }
            )

          school_visit_occupations =
            person_school_visit_occupations ++ auto_tracing_school_visit_occupations

          step = %__MODULE__{
            scholar: case.auto_tracing.scholar,
            school_visits: case.auto_tracing.school_visits,
            employed:
              case person_occupations do
                [_occupations | _rest] -> true
                [] -> case.auto_tracing.employed
              end,
            occupations: person_occupations,
            school_visit_occupations: school_visit_occupations
          }

          IO.inspect(case.person.affiliations)

          assign(socket,
            step: step,
            changeset: %Ecto.Changeset{changeset(step) | action: :validate},
            person: case.person,
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "add_school_visit",
        _params,
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Changeset{
         changeset(
           step,
           changeset_add_to_params(changeset, :school_visits, %{
             uuid: Ecto.UUID.generate()
           })
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_school_visit",
        %{"value" => school_visit_uuid},
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_remove_from_params_by_id(changeset, :school_visits, %{
             uuid: school_visit_uuid
           })
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_school",
        %{"uuid" => organisation_uuid, "subject" => school_uuid} = _params,
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
             :school_visits,
             %{uuid: school_uuid},
             &Map.put(&1, "known_school_uuid", organisation_uuid)
           )
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_school",
        %{"subject" => school_uuid} = _params,
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
             :school_visits,
             %{uuid: school_uuid},
             &Map.put(&1, "known_school_uuid", nil)
           )
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_affiliation_organisation",
        %{"uuid" => organisation_uuid, "subject" => occupation_uuid} = _params,
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
             :occupations,
             %{uuid: occupation_uuid},
             &Map.put(&1, "known_organisation_uuid", organisation_uuid)
           )
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_affiliation_organisation",
        %{"subject" => occupation_uuid} = _params,
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
             :occupations,
             %{uuid: occupation_uuid},
             &Map.put(&1, "known_organisation_uuid", nil)
           )
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "add_occupation",
        _params,
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(socket,
       changeset: %Changeset{
         changeset(
           step,
           changeset_add_to_params(changeset, :occupations, %{
             uuid: Ecto.UUID.generate()
           })
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "remove_occupation",
        %{"value" => occupation_uuid},
        %Socket{assigns: %{step: step, changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       %Changeset{
         changeset(
           step,
           changeset_remove_from_params_by_id(changeset, :occupations, %{uuid: occupation_uuid})
         )
         | action: :validate
       }
     )}
  end

  def handle_event("validate", %{"employer" => params}, socket) do
    params =
      params
      |> Map.put_new("occupations", [])
      |> Map.put_new("school_visit_occupations", [])
      |> Map.put_new("school_visits", [])

    {:noreply,
     assign(socket,
       changeset: %Changeset{changeset(socket.assigns.step, params) | action: :validate}
     )}
  end

  def handle_event(
        "advance",
        _params,
        %Socket{assigns: %{person: person, changeset: changeset, auto_tracing: auto_tracing}} =
          socket
      ) do
    socket =
      changeset
      |> apply_action(:compute)
      |> case do
        {:error, changeset} ->
          assign(socket, changeset: changeset)

        {:ok, step} ->
          person_changeset = add_affiliations_to_person(person, step)

          {:ok, _person} = CaseContext.update_person(person_changeset)

          auto_tracing_changeset =
            auto_tracing
            |> AutoTracingContext.change_auto_tracing()
            |> add_occupations(step)
            |> put_embed(:school_visits, [])

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          auto_tracing_changeset =
            auto_tracing
            |> AutoTracingContext.change_auto_tracing()
            |> add_visited_schools(step)

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          {:ok, auto_tracing} =
            if auto_tracing.scholar do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(auto_tracing, :school_related)
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :school_related)
            end

          {:ok, auto_tracing} =
            if length(Map.get(auto_tracing, :occupations, [])) > 0 do
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_add_problem(auto_tracing, :new_employer)
            else
              {:ok, _auto_tracing} =
                AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :new_employer)
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :employer)

          push_redirect(socket,
            to:
              Routes.auto_tracing_vaccination_path(
                socket,
                :vaccination,
                socket.assigns.auto_tracing.case_uuid
              )
          )
      end

    {:noreply, socket}
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:scholar, :employed])
    |> validate_school_related()
    |> merge_visit_occupations()
    |> check_employed()
    |> validate_occupation()
    |> validate_required([:scholar, :employed])
  end

  @spec validate_school_related(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_school_related(changeset) do
    changeset
    |> fetch_field!(:scholar)
    |> case do
      true ->
        cast_embed(changeset, :school_visits,
          required: true,
          required_message:
            gettext(
              "please add at least one educational institution that you visited during the period in consideration"
            )
        )

      _else ->
        put_embed(changeset, :school_visits, [])
    end
  end

  @spec validate_occupation(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_occupation(changeset) do
    changeset
    |> fetch_field!(:employed)
    |> case do
      true ->
        if Enum.empty?(
             fetch_field!(changeset, :school_visit_occupations) ++
               fetch_field!(changeset, :occupations)
           ) do
          cast_embed(changeset, :occupations,
            required: true,
            required_message: gettext("please add at least one occupation")
          )
        else
          cast_embed(changeset, :occupations)
        end

      _else ->
        put_embed(changeset, :occupations, [])
    end
  end

  defp merge_visit_occupations(changeset) do
    visits_to_add =
      changeset
      |> get_field(:school_visits, [])
      |> Enum.reduce([], fn
        %SchoolVisit{
          uuid: school_visit_uuid,
          visit_reason: visit_reason,
          known_school_uuid: known_school_uuid,
          unknown_school: unknown_school,
          is_occupied: true
        },
        acc
        when not is_nil(known_school_uuid) or not is_nil(unknown_school) ->
          acc ++
            [
              %Occupation{
                uuid: Ecto.UUID.generate(),
                kind: visit_reason_to_kind(visit_reason),
                related_school_visit_uuid: school_visit_uuid,
                known_organisation_uuid: known_school_uuid,
                not_found: if(unknown_school, do: true, else: false),
                unknown_organisation: unknown_school
              }
            ]

        %SchoolVisit{}, acc ->
          acc
      end)

    put_embed(
      changeset,
      :school_visit_occupations,
      visits_to_add
    )
  end

  defp add_affiliations_to_person(person, %__MODULE__{
         occupations: occupations,
         school_visit_occupations: school_visit_occupations
       }) do
        IO.inspect(person.affiliations, label: "PER")
    existing_organisation_uuids = Enum.map(person.affiliations, & &1.organisation_uuid)
    new_occupation_organisation_uuids = Enum.map(occupations, & &1.known_organisation_uuid)

    keep_affiliations =
      person.affiliations
      |> Enum.filter(&(&1.organisation_uuid in new_occupation_organisation_uuids))
      |> Enum.map(fn %Affiliation{organisation_uuid: organisation_uuid} = affiliation ->
        occupation =
          Enum.find(
            occupations,
            &match?(%Occupation{known_organisation_uuid: ^organisation_uuid}, &1)
          )

        OrganisationContext.change_affiliation(affiliation, %{kind: occupation.kind})
      end)

    new_affiliations =
      occupations
      |> Enum.reject(&match?(%Occupation{known_organisation_uuid: nil}, &1))
      |> Enum.reject(&(&1.known_organisation_uuid in existing_organisation_uuids))
      |> Enum.map(
        &%Affiliation{
          uuid: Ecto.UUID.generate(),
          kind: &1.kind,
          kind_other: &1.kind_other,
          organisation_uuid: &1.known_organisation_uuid
        }
      )

    school_visit_affiliations =
      school_visit_occupations
      |> Enum.reject(&match?(%Occupation{known_organisation_uuid: nil}, &1))
      #|> Enum.reject(&(&1.known_organisation_uuid in existing_organisation_uuids))
      |> Enum.map(
        &%Affiliation{
          uuid: Ecto.UUID.generate(),
          kind: &1.kind,
          kind_other: &1.kind_other,
          organisation_uuid: &1.known_organisation_uuid,
          related_school_visit_uuid: &1.related_school_visit_uuid
        }
      )

    person
    |> CaseContext.change_person()
    |> put_assoc(
      :affiliations,
      keep_affiliations ++ new_affiliations ++ school_visit_affiliations
    )
  end

  defp add_visited_schools(auto_tracing_changeset, %__MODULE__{school_visits: school_visits}) do
    put_embed(auto_tracing_changeset, :school_visits, school_visits)
  end

  defp add_occupations(auto_tracing_changeset, %__MODULE__{
         occupations: occupations,
         school_visit_occupations: school_visit_occupations,
         scholar: scholar,
         employed: employed
       }) do
    auto_tracing_changeset
    |> put_embed(
      :occupations,
      occupations ++ school_visit_occupations
      # Enum.filter(occupations, &match?(%Occupation{known_organisation_uuid: nil}, &1)) ++
      #   Enum.filter(
      #     school_visit_occupations,
      #     &match?(%Occupation{known_organisation_uuid: nil}, &1)
      #   )
    )
    |> put_change(:scholar, scholar)
    |> put_change(:employed, employed)
  end

  defp check_employed(changeset) do
    if length(get_field(changeset, :school_visit_occupations)) > 0,
      do: put_change(changeset, :employed, true),
      else: changeset
  end

  defp visit_reason_to_kind(:student), do: :scholar

  defp visit_reason_to_kind(visit_reason) when visit_reason in [:professor, :employee],
    do: :employee
end
