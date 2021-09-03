defmodule HygeiaWeb.AutoTracingLive.Transmission do
  @moduledoc false

  use HygeiaWeb, :surface_view

  use Hygeia, :model

  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing.Propagator
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TelephoneInput
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LiveRedirect

  @type t :: %__MODULE__{
          known: boolean,
          propagator_known: boolean | nil,
          propagator: Propagator.t() | nil,
          transmission: Transmission.t() | nil
        }

  @type empty :: %__MODULE__{
          known: boolean | nil,
          propagator_known: boolean | nil,
          propagator: Propagator.t() | nil,
          transmission: Transmission.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :known, :boolean
    field :propagator_known, :boolean

    embeds_one :propagator, Propagator, on_replace: :update
    embeds_one :transmission, Transmission, on_replace: :update
  end

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        transmission =
          if uuid = case.auto_tracing.transmission_uuid do
            CaseContext.get_transmission!(uuid)
          end

        step = %__MODULE__{
          known: case.auto_tracing.transmission_known,
          propagator_known: case.auto_tracing.propagator_known,
          transmission: transmission,
          propagator: case.auto_tracing.propagator
        }

        assign(socket,
          changeset: %Ecto.Changeset{changeset(step) | action: :validate},
          transmission: transmission,
          case: case,
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
        "validate",
        %{"transmission" => transmission},
        socket
      ) do
    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       changeset(%__MODULE__{}, transmission)
       | action: :validate
     })}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        _params,
        %Socket{
          assigns: %{changeset: changeset, auto_tracing: auto_tracing, transmission: transmission}
        } = socket
      ) do
    transmission = if transmission == nil, do: %Transmission{}, else: transmission

    socket =
      changeset
      |> apply_action(:validate)
      |> case do
        {:error, changeset} ->
          assign(socket, changeset: changeset)

        {:ok, step} ->
          {:ok, auto_tracing} =
            if fetch_field!(changeset, :known) do
              transmission_params =
                step.transmission
                |> Map.take([:date, :recipient_internal, :recipient_case_uuid])
                |> Map.put(:infection_place, unpack(step.transmission.infection_place))

              transmission_changeset =
                CaseContext.change_transmission(transmission, transmission_params, %{
                  place_type_required: true
                })

              {:ok, transmission} =
                if transmission.uuid do
                  CaseContext.update_transmission(transmission_changeset)
                else
                  CaseContext.create_transmission(apply_changes(transmission_changeset), %{})
                end

              auto_tracing_changeset =
                AutoTracingContext.change_auto_tracing(auto_tracing, %{
                  transmission_known: true,
                  transmission_uuid: transmission.uuid
                })

              {:ok, _auto_tracing} =
                if fetch_field!(changeset, :propagator_known) do
                  {:ok, auto_tracing} =
                    auto_tracing_changeset
                    |> AutoTracingContext.change_auto_tracing(%{propagator_known: true})
                    |> put_embed(:propagator, fetch_field!(changeset, :propagator))
                    |> AutoTracingContext.update_auto_tracing()

                  AutoTracingContext.auto_tracing_add_problem(auto_tracing, :link_propagator)
                else
                  {:ok, auto_tracing} =
                    auto_tracing_changeset
                    |> AutoTracingContext.change_auto_tracing(%{propagator_known: false})
                    |> put_change(:propagator, nil)
                    |> AutoTracingContext.update_auto_tracing()

                  AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :link_propagator)
                end
            else
              if auto_tracing.transmission_uuid do
                {:ok, _transmission} = CaseContext.delete_transmission(transmission)
              end

              {:ok, auto_tracing} =
                auto_tracing
                |> AutoTracingContext.change_auto_tracing(%{
                  transmission_known: false,
                  propagator_known: nil
                })
                |> put_change(:propagator, nil)
                |> put_change(:transmission_uuid, nil)
                |> AutoTracingContext.update_auto_tracing()

              AutoTracingContext.auto_tracing_remove_problem(auto_tracing, :link_propagator)
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :transmission)

          push_redirect(socket,
            to:
              Routes.auto_tracing_contact_persons_path(
                socket,
                :contact_persons,
                socket.assigns.auto_tracing.case_uuid
              )
          )
      end

    {:noreply, socket}
  end

  @spec changeset(transmission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(transmission, attrs \\ %{}) do
    transmission
    |> cast(attrs, [
      :known,
      :propagator_known
    ])
    |> validate_required(:known)
    |> validate_transmission_required()
    |> validate_propagator_required()
  end

  defp validate_transmission_required(changeset) do
    changeset
    |> fetch_field!(:known)
    |> case do
      true ->
        cast_embed(changeset, :transmission,
          with: &Transmission.changeset(&1, &2, %{place_type_required: true}),
          required: true,
          required_message:
            gettext(
              "please fill in the information about the place where you contracted the virus"
            )
        )

      _else ->
        put_change(changeset, :transmission, nil)
        put_change(changeset, :propagator_known, nil)
    end
  end

  defp validate_propagator_required(changeset) do
    changeset
    |> fetch_field!(:propagator_known)
    |> case do
      true ->
        cast_embed(changeset, :propagator,
          required: true,
          required_message:
            gettext("please fill in the information of the person who passed on the virus to you")
        )

      _else ->
        put_change(changeset, :propagator, nil)
    end
  end

  defp unpack(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unpack(value)} end)
    |> Map.new()
  end

  defp unpack(other), do: other
end
