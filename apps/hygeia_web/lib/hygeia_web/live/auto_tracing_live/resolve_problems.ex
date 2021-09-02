defmodule HygeiaWeb.AutoTracingLive.ResolveProblems do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.OrganisationContext.Affiliation
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

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [affiliations: []], auto_tracing: [])

    propagator_internal =
      case case.auto_tracing do
        %AutoTracing{propagator_known: true} -> true
        _other -> nil
      end

    {auto_tracing, should_redirect?} =
      if params["resolve_problem"] do
        {:ok, auto_tracing} =
          AutoTracingContext.auto_tracing_resolve_problem(
            case.auto_tracing,
            String.to_existing_atom(params["resolve_problem"])
          )

        {auto_tracing, true}
      else
        {case.auto_tracing, false}
      end

    socket =
      if authorized?(auto_tracing, :resolve_problems, get_auth(socket)) do
        socket
        |> assign(
          case: case,
          person: case.person,
          auto_tracing: auto_tracing,
          link_propagator_opts_changeset:
            LinkPropagatorOpts.changeset(%LinkPropagatorOpts{}, %{
              propagator_internal: propagator_internal
            })
        )
        |> then(fn socket ->
            if should_redirect? do
              push_redirect(socket,
                to: Routes.auto_tracing_resolve_problems_path(socket, :resolve_problems, case.uuid)
              )
            else
              socket
            end
        end)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
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
     assign(socket, :link_propagator_opts_changeset, %{
       LinkPropagatorOpts.changeset(
         %LinkPropagatorOpts{},
         update_changeset_param(
           socket.assigns.link_propagator_opts_changeset,
           :propagator_case_uuid,
           fn _value_before -> params["uuid"] end
         )
       )
       | action: :validate
     })}
  end

  def handle_event("link_propagator_opts_submit", params, socket) do
    socket =
      %LinkPropagatorOpts{}
      |> LinkPropagatorOpts.changeset(params["link_propagator_opts"] || %{})
      |> Ecto.Changeset.apply_action(:apply)
      |> case do
        {:ok, opts} ->
          {:ok, transmission} =
            socket.assigns.auto_tracing.transmission_uuid
            |> CaseContext.get_transmission!()
            |> CaseContext.update_transmission(
              Map.take(opts, [:propagator_case_uuid, :propagator_ism_id, :propagator_internal])
            )

          push_redirect(socket,
            to:
              Routes.transmission_show_path(
                socket,
                :edit,
                transmission.uuid,
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

        {:error, changeset} ->
          assign(socket, link_propagator_opts_changeset: changeset)
      end

    {:noreply, socket}
  end

  def handle_event(
        "select_occupation_organisation",
        %{"subject" => occupation_uuid, "uuid" => organisation_uuid},
        socket
      ) do
    {[occupation], rest} =
      Enum.split_with(socket.assigns.auto_tracing.occupations, &(&1.uuid == occupation_uuid))

    {:ok, person} =
      socket.assigns.person
      |> CaseContext.change_person()
      |> Ecto.Changeset.put_assoc(
        :affiliations,
        socket.assigns.person.affiliations ++
          [
            %Affiliation{
              uuid: Ecto.UUID.generate(),
              kind: occupation.kind,
              kind_other: occupation.kind_other,
              organisation_uuid: organisation_uuid
            }
          ]
      )
      |> CaseContext.update_person()

    {:ok, auto_tracing} =
      socket.assigns.auto_tracing
      |> AutoTracingContext.change_auto_tracing()
      |> Ecto.Changeset.put_embed(:occupations, rest)
      |> AutoTracingContext.update_auto_tracing()

    {:ok, auto_tracing} =
      case rest do
        [] -> AutoTracingContext.auto_tracing_resolve_problem(auto_tracing, :new_employer)
        _more -> {:ok, auto_tracing}
      end

    {:noreply, assign(socket, person: person, auto_tracing: auto_tracing)}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %AutoTracing{} = auto_tracing, _version}, socket) do
    {:noreply, assign(socket, auto_tracing: auto_tracing)}
  end

  def handle_info({:deleted, %AutoTracing{}, _version}, socket) do
    {:noreply,
     redirect(socket, to: Routes.case_base_data_path(socket, :show, socket.assigns.case))}
  end

  def handle_info({:put_flash, type, msg}, socket), do: {:noreply, put_flash(socket, type, msg)}

  def handle_info(_other, socket), do: {:noreply, socket}
end
