defmodule HygeiaWeb.AutoTracingLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.Helpers.Empty
  # alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  # alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  # alias Surface.Components.Form.Select
  alias Surface.Components.Form.TelephoneInput
  # alias Surface.Components.Form.TextArea
  # alias Surface.Components.Form.TextInput

  @steps [
    start: gettext("Greeting"),
    address: gettext("Address"),
    contact_methods: gettext("Contact Methods"),
    employer: gettext("Employer"),
    vaccination: gettext("Vaccination"),
    covid_app: gettext("Covid App"),
    clinical: gettext("Clinical"),
    transmission: gettext("Transmission"),
    finished: gettext("Finished")
  ]

  data step, :atom, default: :base
  data case_changeset, :map
  data person_changeset, :map
  data changeset, :map

  @impl Phoenix.LiveView
  def mount(%{"case_uuid" => case_uuid} = _params, _session, socket) do
    case = CaseContext.get_case!(case_uuid)

    socket =
      if authorized?(AutoTracing, :create, get_auth(socket), %{case: case}) do
        {:ok, auto_tracing} =
          case AutoTracingContext.get_auto_tracing_by_case(case) do
            nil ->
              AutoTracingContext.create_auto_tracing(case, %{
                current_step: :start,
                last_completed_step: :start
              })

            auto_tracing ->
              {:ok, auto_tracing}
          end

        socket
        |> assign(
          case: case,
          auto_tracing: auto_tracing
        )
        |> load_data(auto_tracing.current_step)
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.possible_index_submission_create_path(socket, :create, case)
            )
        )
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"case" => %{"monitoring" => monitoring}},
        socket
      ) do
    socket =
      assign(socket, :case_changeset, %{
        (socket.assigns.case
         |> CaseContext.change_case(%{monitoring: monitoring}))
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"person" => %{"address" => address}},
        socket
      ) do
    socket =
      assign(socket, :person_changeset, %{
        (socket.assigns.person
         |> CaseContext.change_person(%{address: address}))
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"auto_tracing" => %{"email" => email, "landline" => landline, "mobile" => mobile}},
        socket
      ) do
    socket =
      assign(socket, :changeset, %{
        AutoTracingContext.change_auto_tracing(socket.assigns.changeset.data, %{
          email: email,
          landline: landline,
          mobile: mobile
        })
        | action: :validate
      })

    socket =
      if socket.assigns.changeset.valid? and
           (not is_nil(socket.assigns.changeset.data.email) or
              not is_nil(socket.assigns.changeset.data.landline) or
              not is_nil(socket.assigns.changeset.data.mobile) or
              socket.assigns.changeset.changes != %{}) do
        contact_methods =
          socket.assigns.changeset.changes
          |> Map.to_list()
          |> Enum.map(fn {k, v} -> %{type: k, value: v} end)

        assign(socket, :person_changeset, %{
          (socket.assigns.person
           |> CaseContext.change_person(%{contact_methods: contact_methods}))
          | action: :update
        })
      else
        assign(socket, :person_changeset, %{socket.assigns.person_changeset | valid?: false})
      end

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event("goto_step", %{"active" => "1", "step" => step}, socket) do
    IO.inspect(step, label: "******** GOTO STEP")
    {:noreply, load_data(socket, String.to_existing_atom(step))}
  end

  def handle_event("goto_step", _params, socket), do: {:noreply, socket}

  # def handle_event(
  #       "save",
  #       %{"possible_index_submission" => possible_index_submission_params},
  #       socket
  #     ) do
  #   socket.assigns.case
  #   |> CaseContext.create_possible_index_submission(possible_index_submission_params)
  #   |> case do
  #     {:ok, _possible_index_submission} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, gettext("Possible index submission created successfully"))
  #        |> push_redirect(
  #          to: Routes.possible_index_submission_index_path(socket, :index, socket.assigns.case)
  #        )}

  #     {:error, changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

  def handle_event("advance", _params, socket) do
    case socket.assigns.auto_tracing.current_step do
      :address ->
        if not Empty.is_empty?(socket.assigns.case_changeset, []) do
          CaseContext.update_case(socket.assigns.case_changeset)
        end

        if not Empty.is_empty?(socket.assigns.person_changeset, [:suspected_duplicates_uuid]) do
          CaseContext.update_person(socket.assigns.person_changeset)
        end

      :contact_methods ->
        if not Empty.is_empty?(socket.assigns.changeset, []) do
          CaseContext.update_person(socket.assigns.person_changeset)
        end

      _other ->
        IO.inspect("NEXT STEP")
    end

    # socket.assigns.auto_tracing.current_step
    # |> steps(socket.assigns.auto_tracing.last_completed_step)
    # |> IO.inspect()
    # |> Enum.find_value(fn
    #   {step, {_name, false, false}} -> step
    #   _other -> false
    # end)

    current_step_index =
      @steps
      |> Enum.find_index(fn {step, _name} -> step == socket.assigns.auto_tracing.current_step end)

    {new_step, _name} = Enum.fetch!(@steps, current_step_index + 1)
    IO.inspect(new_step, label: "***** NEW STEP")

    last_completed_step_index =
      @steps
      |> Enum.find_index(fn {step, _name} ->
        step == socket.assigns.auto_tracing.last_completed_step
      end)

    socket =
      if current_step_index > last_completed_step_index do
        {:ok, auto_tracing} =
          AutoTracingContext.update_auto_tracing(socket.assigns.auto_tracing, %{
            last_completed_step: socket.assigns.auto_tracing.current_step
          })

        assign(socket, auto_tracing: auto_tracing)
      else
        socket
      end

    {:noreply, load_data(socket, new_step)}
  end

  defp get_contact_methods(person) do
    email =
      Enum.find_value(person.contact_methods, fn
        %{type: :email, value: value} -> value
        _contact_method -> false
      end)

    mobile =
      Enum.find_value(person.contact_methods, fn
        %{type: :mobile, value: value} -> value
        _contact_method -> false
      end)

    landline =
      Enum.find_value(person.contact_methods, fn
        %{type: :landline, value: value} -> value
        _contact_method -> false
      end)

    %{email: email, mobile: mobile, landline: landline}
  end

  defp load_data(socket, new_step) do
    case = CaseContext.get_case!(socket.assigns.case.uuid)
    person = CaseContext.get_person!(case.person_uuid)

    socket =
      assign(socket,
        case: case,
        case_changeset: Case.changeset(case, %{}),
        person: person,
        person_changeset: Person.changeset(person, %{})
      )

    update_params =
      case new_step do
        :contact_methods -> Map.put_new(get_contact_methods(person), :current_step, new_step)
        _other -> %{current_step: new_step}
      end

    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(socket.assigns.auto_tracing, update_params)

    assign(socket,
      auto_tracing: auto_tracing,
      changeset: AutoTracing.changeset(auto_tracing),
      step: new_step
    )

    # {:ok, auto_tracing} =
    #   case new_step do
    #     # case socket.assigns.auto_tracing.current_step do
    #     :contact_methods ->
    #       contact_methods = get_contact_methods(person)

    #       AutoTracingContext.update_auto_tracing(
    #         socket.assigns.auto_tracing,
    #         Map.put_new(contact_methods, :current_step, new_step)
    #       )

    #     _other ->
    #       {:ok, AutoTracingContext.get_auto_tracing!(socket.assigns.auto_tracing.uuid)}
    #   end

    # IO.inspect(person.contact_methods, label: "***** PERSON.CONTACT_METHODS")
    # IO.inspect(auto_tracing, label: "***** AUTO_TRACING")
    # IO.inspect(auto_tracing.mobile, label: "***** AUTO_TRACING.MOBILE")
    # IO.inspect(auto_tracing.email, label: "***** AUTO_TRACING.EMAIL")
    # IO.inspect(auto_tracing.landline, label: "***** AUTO_TRACING.LANDLINE")
  end

  defp errors_in?(changeset, paths) do
    paths
    |> Enum.map(fn
      field when is_atom(field) -> [field]
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
    end)
    |> Enum.any?(&has_error?(changeset, &1))
  end

  defp has_error?(nil, _path), do: false

  defp has_error?(%Ecto.Changeset{errors: errors}, [field]) do
    Keyword.has_key?(errors, field)
  end

  defp has_error?(%Ecto.Changeset{errors: errors} = changeset, [relation_or_embed | path_tail]) do
    Keyword.has_key?(errors, relation_or_embed) ||
      changeset
      |> Ecto.Changeset.get_change(relation_or_embed)
      |> has_error?(path_tail)
  end

  defp steps(current_step, last_completed_step) do
    current_index =
      @steps
      |> Keyword.keys()
      |> Enum.find_index(&(&1 == current_step))

    last_completed_index =
      @steps
      |> Keyword.keys()
      |> Enum.find_index(&(&1 == last_completed_step))

    @steps
    |> Enum.with_index()
    |> Enum.map(fn {{step, name}, index} ->
      {step, {name, index == current_index, index <= last_completed_index}}
    end)
  end
end
