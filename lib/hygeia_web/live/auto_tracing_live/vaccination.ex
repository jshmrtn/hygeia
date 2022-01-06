defmodule HygeiaWeb.AutoTracingLive.Vaccination do
  @moduledoc false

  use Hygeia, :model
  use HygeiaWeb, :surface_view

  alias Phoenix.LiveView.Socket

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
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :is_externally_convalescent, :boolean
    field :has_received_vaccine, :boolean
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
            is_externally_convalescent: case.person.convalescent_externally,
            has_received_vaccine: case.person.is_vaccinated,
            number_of_vaccine_shots:
              if(Enum.empty?(case.person.vaccination_shots),
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

  @impl Phoenix.LiveView
  def handle_event("validate", %{"vaccination" => vaccination_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       changeset(apply_changes(socket.assigns.changeset), vaccination_params)
       | action: :validate
     })}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "advance",
        _params,
        %Socket{assigns: %{changeset: changeset, auto_tracing: auto_tracing}} = socket
      ) do
    socket =
      changeset
      |> apply_action(:compute)
      |> case do
        {:error, changeset} ->
          assign(socket, changeset: changeset)

        {:ok, step} ->
          {:ok, person} =
            socket.assigns.person
            |> CaseContext.change_person(%{
              is_vaccinated: step.has_received_vaccine,
              convalescent_externally: step.is_externally_convalescent
            })
            |> put_assoc(:vaccination_shots, step.vaccination_shots)
            |> CaseContext.update_person()

          {:ok, auto_tracing} =
            case person do
              %Person{is_vaccinated: true} ->
                AutoTracingContext.auto_tracing_add_problem(
                  auto_tracing,
                  :vaccination_failure
                )

              %Person{} ->
                AutoTracingContext.auto_tracing_remove_problem(
                  auto_tracing,
                  :vaccination_failure
                )
            end

          {:ok, _auto_tracing} = AutoTracingContext.advance_one_step(auto_tracing, :vaccination)

          push_redirect(socket,
            to:
              Routes.auto_tracing_covid_app_path(
                socket,
                :covid_app,
                auto_tracing.case_uuid
              )
          )
      end

    {:noreply, socket}
  end

  defp changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :has_received_vaccine,
      :number_of_vaccine_shots,
      :is_externally_convalescent
    ])
    |> validate_required([:has_received_vaccine])
    |> validate_vaccine_received()
    |> prefill_number_of_vaccines_received()
  end

  defp validate_vaccine_received(changeset) do
    changeset
    |> fetch_field!(:has_received_vaccine)
    |> case do
      true ->
        changeset
        |> validate_required([:is_externally_convalescent])
        |> fetch_field!(:number_of_vaccine_shots)
        |> case do
          nil ->
            changeset
            |> validate_required([:number_of_vaccine_shots])
            |> put_change(:number_of_vaccine_shots, nil)

          _else ->
            changeset
            |> validate_required([:number_of_vaccine_shots])
            |> validate_number(:number_of_vaccine_shots, greater_than: 0, less_than: 15)
        end

      _else ->
        changeset
        |> put_change(:is_externally_convalescent, false)
        |> put_change(:number_of_vaccine_shots, nil)
        |> put_embed(:vaccination_shots, [])
    end
  end

  defp prefill_number_of_vaccines_received(changeset) do
    if fetch_field!(changeset, :has_received_vaccine) != true or
         is_nil(fetch_field!(changeset, :number_of_vaccine_shots)) do
      put_embed(changeset, :vaccination_shots, [])
    else
      changeset = cast_embed(changeset, :vaccination_shots, required: true)
      vaccination_shots = fetch_field!(changeset, :vaccination_shots)

      vaccination_shots_changes =
        get_change(
          changeset,
          :vaccination_shots,
          Enum.map(vaccination_shots, &VaccinationShot.changeset/1)
        )

      number_provided = fetch_field!(changeset, :number_of_vaccine_shots)

      number_available = length(vaccination_shots)

      vaccination_shots =
        if number_provided > number_available do
          vaccination_shots_changes ++
            Enum.reduce(1..(number_provided - number_available), [], fn _i, acc ->
              [VaccinationShot.changeset(%VaccinationShot{})] ++ acc
            end)
        else
          {remaining_vaccination_shots, 0} =
            Enum.reduce(vaccination_shots_changes, {[], number_provided}, fn
              %Ecto.Changeset{action: :delete} = changeset, {list, remaining} ->
                {[changeset | list], remaining}

              %Ecto.Changeset{action: _other} = changeset, {list, remaining} when remaining > 0 ->
                {[changeset | list], remaining - 1}

              _other, {list, 0} ->
                {list, 0}
            end)

          Enum.reverse(remaining_vaccination_shots)
        end

      put_embed(changeset, :vaccination_shots, vaccination_shots)
    end
  end
end
