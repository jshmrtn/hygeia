defmodule HygeiaWeb.AutoTracingLive.Vaccination do
  @moduledoc false

  use Hygeia, :model
  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.VaccinationShot
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :received_vaccine, :boolean
    field :number_of_vaccine_shots, :integer
    embeds_many :vaccination_shots, VaccinationShot, on_replace: :delete
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [vaccination_shots: []], auto_tracing: [])

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

        !AutoTracing.step_available?(case.auto_tracing, :vaccination) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          step = %__MODULE__{
            received_vaccine: case.person.is_vaccinated,
            number_of_vaccine_shots:
              if(
                is_nil(case.person.vaccination_shots) or
                  Enum.empty?(case.person.vaccination_shots),
                do: nil,
                else: length(case.person.vaccination_shots)
              ),
            vaccination_shots: case.person.vaccination_shots
          }

          assign(socket,
            case: case,
            person: case.person,
            changeset: %Ecto.Changeset{changeset(step) | action: :validate},
            auto_tracing: case.auto_tracing
          )
      end

    {:noreply, socket}
  end

  def handle_event("validate", %{"vaccination" => vaccination_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       changeset(apply_changes(socket.assigns.changeset), vaccination_params)
       | action: :validate
     })}
  end

  @impl Phoenix.LiveView
  def handle_event("advance", _params, socket) do
    vaccination_params =
      socket.assigns.changeset
      |> Ecto.Changeset.get_change(
        :vaccination,
        Person.Vaccination.changeset(
          Ecto.Changeset.get_field(socket.assigns.changeset, :vaccination, %Person.Vaccination{}),
          %{}
        )
      )
      |> update_changeset_param(
        :jab_dates,
        &(&1
          |> Kernel.||([])
          |> Enum.reject(fn date -> is_nil(date) end)
          |> Enum.uniq()
          |> Enum.sort_by(
            fn
              date when is_binary(date) -> Date.from_iso8601!(date)
              date -> date
            end,
            {:asc, Date}
          ))
      )

    params =
      update_changeset_param(socket.assigns.changeset, :vaccination, fn _input ->
        vaccination_params
      end)

    {:ok, person} =
      CaseContext.update_person(
        %Ecto.Changeset{socket.assigns.changeset | action: nil},
        params,
        %{vaccination_required: true, initial_nil_jab_date_count: 0}
      )

    {:ok, auto_tracing} =
      case person do
        %Person{is_vaccinated: true} ->
          AutoTracingContext.auto_tracing_add_problem(
            socket.assigns.auto_tracing,
            :vaccination_failure
          )

        %Person{} ->
          AutoTracingContext.auto_tracing_remove_problem(
            socket.assigns.auto_tracing,
            :vaccination_failure
          )
      end

    {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :vaccination)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_covid_app_path(
           socket,
           :covid_app,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  defp changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :received_vaccine,
      :number_of_vaccine_shots
    ])
    |> validate_required([:received_vaccine])
    |> validate_vaccine_received()
    |> prefill_number_of_vaccines_received()
  end

  defp validate_vaccine_received(changeset) do
    changeset
    |> fetch_field!(:received_vaccine)
    |> case do
      true ->
        changeset
        |> validate_required([:number_of_vaccine_shots])
        |> validate_number(:number_of_vaccine_shots, greater_than: 0, less_than: 15)

      _else ->
        changeset
        |> put_change(:number_of_vaccine_shots, nil)
        |> put_embed(:vaccination_shots, [])
    end
  end

  defp prefill_number_of_vaccines_received(changeset) do
    if fetch_field!(changeset, :received_vaccine) != true or
         is_nil(fetch_field!(changeset, :number_of_vaccine_shots)) do
      put_embed(changeset, :vaccination_shots, [])
    else
      vaccination_shots = fetch_field!(changeset, :vaccination_shots)

      number_provided = fetch_field!(changeset, :number_of_vaccine_shots)

      number_available = if is_nil(vaccination_shots), do: 0, else: length(vaccination_shots)

      vaccination_shots =
        if number_provided > number_available do
          padding =
            Enum.reduce(1..(number_provided - number_available), [], fn _i, acc ->
              [%{}] ++ acc
            end)

          vaccination_shots ++ padding
        else
          Enum.take(vaccination_shots, number_provided)
        end

      changeset
      |> put_embed(:vaccination_shots, vaccination_shots)
      |> cast_embed(:vaccination_shots, required: true)
    end
  end
end
