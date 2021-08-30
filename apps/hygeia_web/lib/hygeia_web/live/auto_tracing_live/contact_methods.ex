defmodule HygeiaWeb.AutoTracingLive.ContactMethods do
  @moduledoc false

  use HygeiaWeb, :surface_view
  use Hygeia, :model

  import HygeiaGettext
  import Ecto.Changeset

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.TelephoneInput
  alias Surface.Components.LiveRedirect

  @primary_key false
  embedded_schema do
    field :mobile, :string
    field :landline, :string
    field :email, :string
  end

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        step = struct(__MODULE__, get_contact_methods(case.person))
        changeset = changeset(step)

        assign(socket,
          case: case,
          person: case.person,
          auto_tracing: case.auto_tracing,
          step: step,
          changeset: %Ecto.Changeset{changeset | action: :validate}
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
  def handle_event("validate", %{"contact_methods" => auto_tracing_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       changeset(socket.assigns.step, auto_tracing_params)
       | action: :validate
     })}
  end

  def handle_event("advance", _params, socket) do
    socket =
      socket.assigns.changeset
      |> apply_action(:advance)
      |> case do
        {:error, %Changeset{} = changeset} ->
          assign(socket, :changeset, changeset)

        {:ok, %__MODULE__{mobile: mobile, landline: landline, email: email}} ->
          existing_values = Enum.map(socket.assigns.person.contact_methods, & &1.value)

          {:ok, _person} =
            [mobile: mobile, landline: landline, email: email]
            |> Enum.reject(&is_nil(elem(&1, 1)))
            |> Enum.reject(&(elem(&1, 1) in existing_values))
            |> Enum.map(fn {type, value} ->
              %{type: type, value: value, uuid: Ecto.UUID.generate()}
            end)
            |> Enum.reduce(
              CaseContext.change_person(socket.assigns.person),
              fn new_contact_method, acc ->
                CaseContext.change_person(
                  socket.assigns.person,
                  changeset_add_to_params(
                    acc,
                    :contact_methods,
                    new_contact_method
                  )
                )
              end
            )
            |> CaseContext.update_person()

          {:ok, auto_tracing} =
            AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :contact_methods)

          {:ok, _auto_tracing} =
            AutoTracingContext.auto_tracing_resolve_problem(auto_tracing, :no_contact_method)

          push_redirect(socket,
            to:
              Routes.auto_tracing_employer_path(
                socket,
                :employer,
                socket.assigns.auto_tracing.case_uuid
              )
          )
      end

    {:noreply, socket}
  end

  defp get_contact_methods(person),
    do:
      Enum.reduce(person.contact_methods, %{mobile: nil, landline: nil, email: nil}, fn
        %{type: :email, value: value}, acc -> %{acc | email: value}
        %{type: :mobile, value: value}, acc -> %{acc | mobile: value}
        %{type: :landline, value: value}, acc -> %{acc | landline: value}
        _contact_method, acc -> acc
      end)

  defp changeset(step, attrs \\ %{}) do
    step
    |> cast(attrs, [:mobile, :landline, :email])
    |> validate_and_normalize_phone(:mobile, fn
      :mobile -> :ok
      :fixed_line_or_mobile -> :ok
      :personal_number -> :ok
      :unknown -> :ok
      _other -> {:error, "not a mobile number"}
    end)
    |> validate_and_normalize_phone(:landline, fn
      :fixed_line -> :ok
      :fixed_line_or_mobile -> :ok
      :voip -> :ok
      :personal_number -> :ok
      :uan -> :ok
      :unknown -> :ok
      _other -> {:error, "not a landline number"}
    end)
    |> validate_email(:email)
    |> validate_one_required()
  end

  defp validate_one_required(changeset) do
    [:mobile, :landline, :email]
    |> Enum.map(&fetch_field!(changeset, &1))
    |> Enum.all?(&is_nil/1)
    |> if do
      add_error(
        changeset,
        :mobile,
        dgettext("errors", "at least one contact method must be provided")
      )
    else
      changeset
    end
  end
end
