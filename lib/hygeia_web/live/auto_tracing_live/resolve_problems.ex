defmodule HygeiaWeb.AutoTracingLive.ResolveProblems do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type, as: PossibleIndexType
  alias Hygeia.CaseContext.Entity
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  data case, :map
  data auto_tracing, :map
  data occupation_form, :map, default: %{}

  defmodule AutoTracingNotFoundError do
    @moduledoc false
    defexception plug_status: 404,
                 message: "auto tracing not found",
                 case_uuid: nil

    @impl Exception
    def exception(opts) do
      case_uuid = Keyword.fetch!(opts, :case_uuid)

      %__MODULE__{
        message: "the auto tracing was not found for the case #{case_uuid}",
        case_uuid: case_uuid
      }
    end
  end

  @impl Phoenix.LiveView
  # credo:disable-for-lines:2 Credo.Check.Refactor.ABCSize
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_params(%{"case_uuid" => case_uuid} = params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(
        person: [affiliations: [:organisation, :division]],
        auto_tracing: [],
        visits: [:organisation, :division],
        received_transmissions: [propagator: []],
        tests: []
      )

    socket =
      cond do
        is_nil(case.auto_tracing) ->
          raise AutoTracingNotFoundError, case_uuid: case_uuid

        !authorized?(case.auto_tracing, :resolve_problems, get_auth(socket)) ->
          socket
          |> push_redirect(to: Routes.home_index_path(socket, :index))
          |> put_flash(:error, gettext("You are not authorized to do this action."))

        not is_nil(params["resolve_problem"]) ->
          {:ok, _auto_tracing} =
            AutoTracingContext.auto_tracing_resolve_problem(
              case.auto_tracing,
              String.to_existing_atom(params["resolve_problem"])
            )

          push_redirect(socket,
            to: Routes.auto_tracing_resolve_problems_path(socket, :resolve_problems, case.uuid)
          )

        true ->
          Phoenix.PubSub.subscribe(Hygeia.PubSub, "auto_tracings:#{case.auto_tracing.uuid}")

          assign(socket,
            case: case,
            person: case.person,
            auto_tracing: case.auto_tracing,
            possible_transmission_changeset: %Ecto.Changeset{
              CaseContext.change_transmission(
                case.auto_tracing.possible_transmission || %Transmission{},
                %{
                  type: :contact_person,
                  propagator_internal:
                    case case.auto_tracing.propagator_known do
                      true -> true
                      nil -> nil
                      false -> nil
                    end
                }
              )
              | action: :validate
            }
          )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("resolve", %{"problem" => "no_reaction"}, socket) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(socket.assigns.auto_tracing, %{
        started_at: DateTime.utc_now()
      })

    {:ok, auto_tracing} =
      AutoTracingContext.auto_tracing_resolve_problem(auto_tracing, :no_reaction)

    {:noreply, assign(socket, auto_tracing: auto_tracing)}
  end

  @impl Phoenix.LiveView
  def handle_event("resolve", %{"problem" => problem}, socket) do
    {:ok, auto_tracing} =
      AutoTracingContext.auto_tracing_resolve_problem(
        socket.assigns.auto_tracing,
        String.to_existing_atom(problem)
      )

    {:noreply, assign(socket, auto_tracing: auto_tracing)}
  end

  def handle_event("delete_person", _params, socket) do
    true = authorized?(socket.assigns.case.person, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_person(socket.assigns.case.person)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Person deleted successfully"))
     |> redirect(to: Routes.person_index_path(socket, :index))}
  end

  def handle_event(
        "possible_transmission_change",
        %{"possible_transmission" => possible_transmission_opts} = _params,
        %Socket{assigns: %{auto_tracing: auto_tracing}} = socket
      ) do
    {:noreply,
     assign(socket,
       possible_transmission_changeset: %{
         CaseContext.change_transmission(
           auto_tracing.possible_transmission,
           possible_transmission_opts
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "possible_transmission_change",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "change_possible_transmission_propagator_case",
        params,
        %Socket{assigns: %{auto_tracing: auto_tracing}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :possible_transmission_changeset,
       %Ecto.Changeset{
         CaseContext.change_transmission(
           auto_tracing.possible_transmission,
           update_changeset_param(
             socket.assigns.possible_transmission_changeset,
             :propagator_case_uuid,
             fn _value_before -> params["uuid"] end
           )
         )
         | action: :validate
       }
     )}
  end

  def handle_event(
        "create_transmission",
        _params,
        %Socket{assigns: %{possible_transmission_changeset: possible_transmission_changeset}} =
          socket
      ) do
    socket =
      possible_transmission_changeset
      |> Ecto.Changeset.apply_action(:apply)
      |> case do
        {:ok, transmission} ->
          push_redirect(socket,
            to:
              Routes.transmission_create_path(
                socket,
                :create,
                %{
                  type: :contact_person,
                  date: if(transmission.date, do: Date.to_iso8601(transmission.date), else: nil),
                  infection_place:
                    Map.merge(
                      unpack(transmission.infection_place),
                      %{known: true}
                    ),
                  propagator_internal: transmission.propagator_internal,
                  propagator_case_uuid: transmission.propagator_case_uuid,
                  propagator_ism_id: transmission.propagator_ism_id,
                  recipient_internal: transmission.recipient_internal,
                  recipient_case_uuid: transmission.recipient_case_uuid,
                  return_url:
                    Routes.auto_tracing_resolve_problems_path(
                      socket,
                      :resolve_problems,
                      socket.assigns.case,
                      resolve_problem: :possible_transmission
                    )
                }
              )
          )

        {:error, changeset} ->
          assign(socket, possible_transmission_changeset: changeset)
      end

    {:noreply, socket}
  end

  def handle_event(
        "select_affiliation_organisation",
        %{"subject" => affiliation_uuid, "uuid" => organisation_uuid},
        socket
      ) do
    {:ok, affiliation} =
      socket.assigns.person.affiliations
      |> Enum.find(&match?(^affiliation_uuid, &1.uuid))
      |> OrganisationContext.update_affiliation(%{
        organisation_uuid: organisation_uuid,
        unknown_organisation: nil
      })

    :ok = OrganisationContext.propagate_organisation_and_division(affiliation)

    case = Repo.preload(socket.assigns.case, visits: [:organisation, :division])

    person =
      affiliation.person_uuid
      |> CaseContext.get_person!()
      |> Repo.preload(affiliations: [:organisation, :division])

    {:ok, auto_tracing} =
      if Enum.any?(
           person.affiliations,
           &(is_map(&1.unknown_organisation) or is_map(&1.unknown_division))
         ) do
        {:ok, socket.assigns.auto_tracing}
      else
        AutoTracingContext.auto_tracing_resolve_problem(
          socket.assigns.auto_tracing,
          :new_employer
        )
      end

    {:noreply, assign(socket, case: case, person: person, auto_tracing: auto_tracing)}
  end

  def handle_event(
        "select_organisation_division",
        %{"subject" => affiliation_uuid, "uuid" => division_uuid},
        socket
      ) do
    {:ok, affiliation} =
      socket.assigns.person.affiliations
      |> Enum.find(&match?(^affiliation_uuid, &1.uuid))
      |> OrganisationContext.update_affiliation(%{
        division_uuid: division_uuid,
        unknown_division: nil
      })

    :ok = OrganisationContext.propagate_organisation_and_division(affiliation)

    case = Repo.preload(socket.assigns.case, visits: [:organisation, :division])

    person =
      affiliation.person_uuid
      |> CaseContext.get_person!()
      |> Repo.preload(affiliations: [:organisation, :division])

    {:ok, auto_tracing} =
      if Enum.any?(
           person.affiliations,
           &(is_map(&1.unknown_organisation) or is_map(&1.unknown_division))
         ) do
        {:ok, socket.assigns.auto_tracing}
      else
        AutoTracingContext.auto_tracing_resolve_problem(
          socket.assigns.auto_tracing,
          :new_employer
        )
      end

    {:noreply, assign(socket, case: case, person: person, auto_tracing: auto_tracing)}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %AutoTracing{} = auto_tracing, _version}, socket) do
    {:noreply, assign(socket, auto_tracing: auto_tracing)}
  end

  def handle_info({:deleted, %AutoTracing{}, _version}, socket) do
    {:noreply,
     redirect(socket, to: Routes.case_base_data_path(socket, :show, socket.assigns.case))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp get_risk_travels_zip(travels, transmissions) do
    Enum.map(
      travels,
      fn travel ->
        transmission =
          Enum.find(transmissions, fn
            %Transmission{infection_place: %InfectionPlace{address: %Address{country: country}}} ->
              country == travel.country

            _other_transmission ->
              false
          end)

        {travel, transmission}
      end
    )
  end

  defp unpack(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unpack(value)} end)
    |> Map.new()
  end

  defp unpack(other), do: other

  defp phone_to_uri(number) do
    {:ok, parsed} = ExPhoneNumber.parse(number, "CH")
    ExPhoneNumber.format(parsed, :rfc3966)
  end
end
