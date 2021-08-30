defmodule HygeiaWeb.AutoTracingLive.Employer do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing.Occupation
  alias Hygeia.CaseContext
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation
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

    embeds_many :occupations, Occupation, on_replace: :delete
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [:affiliations], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        person_occupations =
          Enum.map(
            case.person.affiliations,
            &%Occupation{
              uuid: Ecto.UUID.generate(),
              kind: &1.kind,
              kind_other: &1.kind_other,
              known_organisation_uuid: &1.organisation_uuid
            }
          )

        occupations = person_occupations ++ case.auto_tracing.occupations

        step = %__MODULE__{
          scholar: case.auto_tracing.scholar,
          employed:
            case occupations do
              [_occupations | _rest] -> true
              [] -> case.auto_tracing.employed
            end,
          occupations: occupations
        }

        assign(socket,
          step: step,
          changeset: %Ecto.Changeset{changeset(step) | action: :validate},
          person: case.person,
          auto_tracing: case.auto_tracing
        )
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
            )
        )
      end

    {:noreply, socket}
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
    params = Map.put_new(params, "occupations", [])

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

          {:ok, person} = CaseContext.update_person(person_changeset)

          person = Repo.preload(person, affiliations: [:organisation])

          auto_tracing_changeset = add_unknown_occupations(auto_tracing, step)

          {:ok, auto_tracing} = AutoTracingContext.update_auto_tracing(auto_tracing_changeset)

          {:ok, auto_tracing} =
            if auto_tracing.scholar or
                 Enum.any?(
                   person.affiliations,
                   &(match?(%Affiliation{kind: :scholar}, &1) or
                       match?(%Affiliation{organisation: %Organisation{type: :school}}, &1))
                 ) do
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
    |> validate_required([:scholar, :employed])
    |> validate_occupation()
  end

  @spec validate_occupation(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_occupation(changeset) do
    changeset
    |> fetch_field!(:employed)
    |> case do
      true -> cast_embed(changeset, :occupations, required: true)
      _else -> put_change(changeset, :occupations, [])
    end
  end

  defp add_affiliations_to_person(person, %__MODULE__{occupations: occupations}) do
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

    person
    |> CaseContext.change_person()
    |> put_assoc(:affiliations, keep_affiliations ++ new_affiliations)
  end

  defp add_unknown_occupations(auto_tracing, %__MODULE__{
         occupations: occupations,
         scholar: scholar,
         employed: employed
       }) do
    auto_tracing
    |> AutoTracingContext.change_auto_tracing()
    |> put_embed(
      :occupations,
      Enum.filter(occupations, &match?(%Occupation{known_organisation_uuid: nil}, &1))
    )
    |> put_change(:scholar, scholar)
    |> put_change(:employed, employed)
  end
end
