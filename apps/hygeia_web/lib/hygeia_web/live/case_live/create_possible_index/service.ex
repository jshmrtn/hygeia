defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.Service do
  import Ecto.Changeset
  import HygeiaWeb.Helpers.Confirmation

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Person
  alias Hygeia.CommunicationContext
  alias Hygeia.Repo

  def upsert(bindings, transmission_data) do
    Repo.transaction(fn ->
      Enum.map(bindings, fn %{
                              person_changeset: person_changeset,
                              case_changeset: case_changeset,
                              reporting: reporting
                            } ->
        person =
          person_changeset
          |> case do
            %Ecto.Changeset{data: %Person{inserted_at: nil}} = person_changeset ->
              {:ok, person} = CaseContext.create_person(person_changeset)
              person

            person_changeset ->
              apply_changes(person_changeset)
          end

        case =
          case_changeset
          |> merge_phases(transmission_data)
          |> case do
            %Ecto.Changeset{data: %Case{inserted_at: nil}} = case_changeset ->
              {:ok, case} = CaseContext.create_case(case_changeset)
              case

            %Ecto.Changeset{} = case_changeset ->
              {:ok, case} = CaseContext.update_case(case_changeset)
              case
          end
          |> Hygeia.Repo.preload(:person)

        insert_transmission(case, transmission_data)

        contact_method_uuids = Enum.map(reporting, fn {uuid, true} -> uuid end)

        {person, case, contact_method_uuids}
      end)
    end)
  end

  defp merge_phases(case_changeset, transmission_data) do
    existing_phases =
      case_changeset
      |> fetch_field!(:phases)

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))
    |> case do
      nil -> manage_existing_phases(case_changeset, existing_phases, transmission_data)
      _index_phase -> case_changeset
    end
  end

  defp manage_existing_phases(case_changeset, existing_phases, transmission_data) do
    date = transmission_data[:date]
    global_type = transmission_data[:type]
    global_type_other = transmission_data[:type_other]

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        if global_type in [:contact_person, :travel] do
          {start_date, end_date} = phase_dates(Date.from_iso8601!(date))

          status_changed_phases =
            Enum.map(existing_phases, fn
              %Case.Phase{quarantine_order: true, start: old_phase_start} = phase ->
                if Date.compare(old_phase_start, start_date) == :lt do
                  %Case.Phase{
                    phase
                    | end: start_date,
                      send_automated_close_email: false
                  }
                else
                  %Case.Phase{phase | quarantine_order: false}
                end

              %Case.Phase{quarantine_order: quarantine_order} = phase
              when quarantine_order in [false, nil] ->
                phase
            end)

          case_changeset
          |> Ecto.Changeset.put_embed(
            :phases,
            status_changed_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  },
                  quarantine_order: true,
                  order_date: DateTime.utc_now(),
                  start: start_date,
                  end: end_date
                }
              ]
          )
        else
          case_changeset
          |> Ecto.Changeset.put_embed(
            :phases,
            existing_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  }
                }
              ]
          )
        end

      %Case.Phase{} ->
        case_changeset
    end
  end

  defp phase_dates(contact_date) do
    case contact_date do
      nil ->
        {nil, nil}

      %Date{} = contact_date ->
        start_date = contact_date
        end_date = Date.add(start_date, 9)

        start_date =
          if Date.compare(start_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            start_date
          end

        end_date =
          if Date.compare(end_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            end_date
          end

        {start_date, end_date}
    end
  end

  @spec insert_transmission(case :: Case.t(), map :: Map.t()) :: Transmission.t()
  def insert_transmission(case, transmission_data) do
    date = transmission_data |> Map.get(:date)
    comment = transmission_data |> Map.get(:comment)
    infection_place = transmission_data |> Map.get(:infection_place)
    propagator_internal = transmission_data |> Map.get(:propagator_internal)
    propagator_ism_id = transmission_data |> Map.get(:propagator_ism_id)
    propagator_case_uuid = transmission_data |> Map.get(:propagator_case_uuid)

    {:ok, _transmission} =
      CaseContext.create_transmission(%{
        comment: comment,
        date: date,
        recipient_internal: true,
        recipient_case_uuid: case.uuid,
        infection_place: unstruct(infection_place),
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        propagator_case_uuid: propagator_case_uuid
      })
  end

  def send_confirmations(socket, tuples, transmission_data) when is_list(tuples) do
    tuples
    |> Enum.each(fn {person, case, reporting} ->
      type = transmission_data |> Map.get(:type)

      email_addresses =
        person
        |> Map.fetch!(:contact_methods)
        |> Enum.filter(&(&1.type == :email and &1.uuid in reporting))
        |> Enum.map(& &1.value)

      phone_numbers =
        person
        |> Map.fetch!(:contact_methods)
        |> Enum.filter(&(&1.type == :mobile and &1.uuid in reporting))
        |> Enum.map(& &1.value)

      [] =
        Task.async(fn -> send_confirmation_emails(socket, case, email_addresses, type) end)
        |> Task.await()
        |> Enum.reject(&match?({:ok, _}, &1))
        |> Enum.reject(&match?({:error, :no_outgoing_mail_configuration}, &1))
        |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

      [] =
        Task.async(fn -> send_confirmation_sms(socket, case, phone_numbers, type) end)
        |> Task.await()
        |> Enum.reject(&match?({:ok, _}, &1))
        |> Enum.reject(&match?({:error, :sms_config_missing}, &1))
        |> Enum.reject(&match?({:error, :not_latest_phase}, &1))
        |> Enum.reject(&match?({:error, :no_quarantine_ordered}, &1))
    end)
  end

  def send_confirmation_emails(socket, case, email_addresses, transmission_type)

  def send_confirmation_emails(_socket, _case, [], _transmission_type),
    do: [{:ok, :no_email}]

  def send_confirmation_emails(
        socket,
        case,
        email_addresses,
        transmission_type
      ) do
    locale = Gettext.get_locale(HygeiaGettext)

    case List.last(case.phases) do
      %Phase{details: %Phase.PossibleIndex{type: ^transmission_type}} = phase ->
        Gettext.put_locale(HygeiaGettext, locale)

        email_addresses
        |> Enum.map(
          &CommunicationContext.create_outgoing_email(
            case,
            &1,
            quarantine_email_subject(),
            quarantine_email_body(socket, case, phase, :email)
          )
        )

      %Phase{} ->
        [{:error, :not_latest_phase}]
    end
  end

  def send_confirmation_sms(socket, case, phone_numbers, transmission_type)

  def send_confirmation_sms(_socket, _case, [], _transmission_type),
    do: [{:ok, :no_mobile_number}]

  def send_confirmation_sms(
        socket,
        case,
        phone_numbers,
        transmission_type
      ) do
    locale = Gettext.get_locale(HygeiaGettext)

    case List.last(case.phases) do
      %Phase{details: %Phase.PossibleIndex{type: ^transmission_type}, quarantine_order: false} ->
        {:error, :no_quarantine_ordered}

      %Phase{details: %Phase.PossibleIndex{type: ^transmission_type}, quarantine_order: true} =
          phase ->
        Gettext.put_locale(HygeiaGettext, locale)

        phone_numbers
        |> Enum.map(
          &CommunicationContext.create_outgoing_sms(case, &1, quarantine_sms(socket, case, phase))
        )

      %Phase{} ->
        [{:error, :not_latest_phase}]
    end
  end

  @spec unstruct(any()) :: Map.t()
  def unstruct(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unstruct(value)} end)
    |> Map.new()
  end

  def unstruct(list) when is_list(list), do: Enum.map(list, &unstruct/1)

  def unstruct(other), do: other
end
