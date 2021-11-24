defmodule HygeiaWeb.AutoTracingLive.ResolveProblems do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  data case, :map
  data auto_tracing, :map
  data link_propagator_opts_changeset, :map
  data occupation_form, :map, default: %{}

  defmodule LinkPropagatorOpts do
    @moduledoc false

    use Hygeia, :model

    alias Hygeia.CaseContext.Case

    @type t :: %__MODULE__{
            propagator_internal: boolean,
            propagator_ism_id: String.t() | nil,
            propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
            propagator_case_uuid: Ecto.UUID.t() | nil
          }

    @type empty :: %__MODULE__{
            propagator_internal: boolean | nil,
            propagator_ism_id: String.t() | nil,
            propagator_case: Ecto.Schema.belongs_to(Case.t()) | nil,
            propagator_case_uuid: Ecto.UUID.t() | nil
          }

    @primary_key false
    embedded_schema do
      field :propagator_ism_id, :string
      field :propagator_internal, :boolean

      belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid
    end

    @spec changeset(link_propagator_opts :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
            Ecto.Changeset.t(t)
    def changeset(link_propagator_opts, attrs) do
      link_propagator_opts
      |> cast(attrs, [
        :propagator_case_uuid,
        :propagator_internal,
        :propagator_ism_id
      ])
      |> CaseContext.Transmission.validate_case(
        :propagator_internal,
        :propagator_ism_id,
        :propagator_case_uuid
      )
    end
  end

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
  def handle_params(%{"case_uuid" => case_uuid} = params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(
        person: [affiliations: [:organisation, :division]],
        auto_tracing: [transmission: []],
        visits: [:organisation, :division],
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

          propagator_attrs =
            case case.auto_tracing.transmission do
              nil ->
                %{}

              transmission ->
                Map.take(transmission, [
                  :propagator_internal,
                  :propagator_ism_id,
                  :propagator_case_uuid
                ])
            end

          propagator_attrs =
            case {case.auto_tracing, propagator_attrs[:propagator_internal]} do
              {%AutoTracing{propagator_known: true}, nil} ->
                Map.put(propagator_attrs, :propagator_internal, true)

              _other ->
                propagator_attrs
            end

          assign(socket,
            case: case,
            person: case.person,
            auto_tracing: case.auto_tracing,
            link_propagator_opts_changeset:
              LinkPropagatorOpts.changeset(%LinkPropagatorOpts{}, propagator_attrs)
          )
      end

    {:noreply, socket}
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
        "link_propagator_opts_change",
        %{"link_propagator_opts" => link_propagator_opts} = _params,
        socket
      ) do
    {:noreply,
     assign(socket,
       link_propagator_opts_changeset: %{
         LinkPropagatorOpts.changeset(%LinkPropagatorOpts{}, link_propagator_opts)
         | action: :validate
       }
     )}
  end

  def handle_event(
        "link_propagator_opts_change",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event("change_propagator_case", params, socket) do
    {:noreply,
     assign(
       socket,
       :link_propagator_opts_changeset,
       %Ecto.Changeset{
         LinkPropagatorOpts.changeset(
           %LinkPropagatorOpts{},
           update_changeset_param(
             socket.assigns.link_propagator_opts_changeset,
             :propagator_case_uuid,
             fn _value_before -> params["uuid"] end
           )
         )
         | action: :validate
       }
     )}
  end

  def handle_event("link_propagator_opts_submit", params, socket) do
    socket =
      %LinkPropagatorOpts{}
      |> LinkPropagatorOpts.changeset(params["link_propagator_opts"] || %{})
      |> Ecto.Changeset.apply_action(:apply)
      |> case do
        {:ok, opts} ->
          push_redirect(socket,
            to:
              Routes.transmission_show_path(
                socket,
                :edit,
                socket.assigns.auto_tracing.transmission_uuid,
                Map.merge(
                  Map.take(opts, [:propagator_case_uuid, :propagator_ism_id, :propagator_internal]),
                  %{
                    return_url:
                      Routes.auto_tracing_resolve_problems_path(
                        socket,
                        :resolve_problems,
                        socket.assigns.case,
                        resolve_problem: :link_propagator
                      )
                  }
                )
              )
          )

        {:error, changeset} ->
          assign(socket, link_propagator_opts_changeset: changeset)
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
end
