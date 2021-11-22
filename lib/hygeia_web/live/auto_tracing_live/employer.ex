defmodule HygeiaWeb.AutoTracingLive.Employer do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.AutoTracingContext.AutoTracing.Occupation
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Entity
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
    embeds_many :occupations, Occupation, on_replace: :delete
  end

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
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
          occupations =
            Enum.map(
              case.person.affiliations,
              &%Occupation{
                uuid: Ecto.UUID.generate(),
                kind: &1.kind,
                kind_other: &1.kind_other,
                not_found: if(&1.unknown_organisation, do: true, else: false),
                known_organisation_uuid: &1.organisation_uuid,
                unknown_organisation: &1.unknown_organisation,
                division_not_found: if(&1.unknown_division, do: true, else: false),
                known_division_uuid: &1.division_uuid,
                unknown_division: &1.unknown_division,
                related_visit_uuid: &1.related_visit_uuid
              }
            )

          step = %__MODULE__{
            employed:
              cond do
                Enum.any?(occupations) -> true
                is_nil(case.auto_tracing.employed) -> nil
                case.auto_tracing.employed and Enum.empty?(occupations) -> nil
                true -> false
              end,
            occupations: occupations
          }

          assign(socket,
            step: step,
            changeset: %Ecto.Changeset{changeset(step) | action: :validate},
            person: case.person,
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_affiliation_organisation",
        %{"subject" => occupation_uuid} = params,
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
             &Map.put(&1, "known_organisation_uuid", params["uuid"])
           )
         )
         | action: :validate
       }
     )}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select_affiliation_division",
        %{"subject" => occupation_uuid} = params,
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
             &Map.put(&1, "known_division_uuid", params["uuid"])
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

        {:ok, %__MODULE__{employed: employed} = step} ->
          {:ok, person} =
            person
            |> add_affiliations_to_person(step)
            |> CaseContext.update_person()

          {:ok, auto_tracing} =
            AutoTracingContext.update_auto_tracing(auto_tracing, %{employed: employed})

          {:ok, auto_tracing} =
            if Enum.any?(
                 person.affiliations,
                 &(is_map(&1.unknown_organisation) or is_map(&1.unknown_division))
               ) do
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
    |> cast(attrs, [:employed])
    |> validate_occupation()
    |> validate_required([:employed])
  end

  defp validate_occupation(changeset) do
    changeset
    |> fetch_field!(:employed)
    |> case do
      true ->
        cast_embed(changeset, :occupations,
          required: true,
          required_message: gettext("please add at least one occupation")
        )

      _else ->
        put_embed(changeset, :occupations, [])
    end
  end

  defp add_affiliations_to_person(person, %__MODULE__{
         occupations: occupations
       }) do
    affiliations =
      Enum.map(
        occupations,
        &%Affiliation{
          uuid: Ecto.UUID.generate(),
          kind: &1.kind,
          kind_other: &1.kind_other,
          organisation_uuid: &1.known_organisation_uuid,
          unknown_organisation: &1.unknown_organisation,
          related_visit_uuid: &1.related_visit_uuid,
          division_uuid: &1.known_division_uuid,
          unknown_division: filter_unknown_division(&1.unknown_division)
        }
      )

    person
    |> CaseContext.change_person()
    |> put_assoc(
      :affiliations,
      affiliations
    )
  end

  defp is_visit_related?(changeset) do
    changeset
    |> fetch_field!(:related_visit_uuid)
    |> case do
      nil -> false
      _uuid -> true
    end
  end

  defp has_related_visit_occupations?(changeset) do
    changeset
    |> fetch_field!(:occupations)
    |> Enum.filter(&(not is_nil(&1.related_visit_uuid)))
    |> Enum.any?()
  end

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
