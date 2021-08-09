defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.Service do
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo

  def upsert(people, transmission_data) do
    Repo.transaction(fn ->
      people
      |> Enum.map(fn
        %Person{inserted_at: nil} = person ->
          person
          |> merge_case_phases(transmission_data)
          |> CaseContext.change_person()
          |> CaseContext.create_person()

        %Person{} = person ->
          person
          |> merge_case_phases(transmission_data)
          |> upsert_person_case()
      end)
      |> Enum.map(fn
        person -> insert_transmission(person, transmission_data)
      end)
    end)
  end

  defp merge_case_phases(person, transmission_data) do
    %{
      date: date,
      type: global_type,
      type_other: global_type_other
    } = transmission_data

    existing_phases =
      person
      |> person_case()
      |> Map.get(:phases)

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        if global_type in [:contact_person, :travel] do
          {start_date, end_date} = phase_dates(date)

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

          person
          |> Map.put(
            :cases,
            person_case(person)
            |> Map.put(
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
            |> then(&[&1])
          )
        else
          person
          |> Map.put(
            :cases,
            person_case(person)
            |> Map.put(
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
            |> then(&[&1])
          )
        end

      %Case.Phase{} ->
        person
    end
  end

  defp upsert_person_case(person) do
    person
    |> person_case()
    |> case do
      %Case{inserted_at: nil} = new_case ->
        new_case
        |> CaseContext.change_case()
        |> CaseContext.create_case()

      %Case{} = old_case ->
        %Case{uuid: old_case.uuid}
        |> CaseContext.change_case(%{
          person_uuid: old_case.person_uuid,
          status: old_case.status,
          tenant_uuid: old_case.tenant_uuid,
          supervisor_uuid: old_case.supervisor_uuid,
          tracer_uuid: old_case.tracer_uuid
        })
        |> Ecto.Changeset.put_embed(:phases, old_case.phases)
        |> Map.put(:errors, [])
        |> Map.put(:valid?, true)
        |> CaseContext.update_case()
    end

    person
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

  @spec insert_transmission(person :: Person.t(), map :: Map.t()) :: Transmission.t()
  def insert_transmission(person, %{
        date: date,
        comment: comment,
        infection_place: infection_place,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        propagator_case_uuid: propagator_case_uuid
      }) do
    {:ok, _transmission} =
      CaseContext.create_transmission(%{
        comment: comment,
        date: date,
        recipient_internal: true,
        recipient_case_uuid: person_case(person).uuid,
        infection_place: unstruct(infection_place),
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        propagator_case_uuid: propagator_case_uuid
      })

    person
  end

  # defp send_confirmation_emails(socket, global, cases)

  # defp send_confirmation_emails(_socket, %CreateSchema{send_confirmation_email: false}, _cases),
  #   do: :ok

  # defp send_confirmation_emails(
  #        socket,
  #        %CreateSchema{send_confirmation_email: true, type: type},
  #        cases
  #      ) do
  #   locale = Gettext.get_locale(HygeiaGettext)

  #   [] =
  #     cases
  #     |> Enum.map(
  #       &Task.async(fn ->
  #         case List.last(&1.phases) do
  #           %Phase{details: %Phase.PossibleIndex{type: ^type}} = phase ->
  #             Gettext.put_locale(HygeiaGettext, locale)

  #             CommunicationContext.create_outgoing_email(
  #               &1,
  #               quarantine_email_subject(),
  #               quarantine_email_body(socket, &1, phase, :email)
  #             )

  #           %Phase{} ->
  #             {:error, :not_latest_phase}
  #         end
  #       end)
  #     )
  #     |> Enum.map(&Task.await/1)
  #     # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  #     |> Enum.reject(&match?({:ok, _}, &1))
  #     |> Enum.reject(&match?({:error, :no_email}, &1))
  #     |> Enum.reject(&match?({:error, :no_outgoing_mail_configuration}, &1))
  #     |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

  #   :ok
  # end

  # defp send_confirmation_sms(socket, global, cases)

  # defp send_confirmation_sms(_socket, %CreateSchema{send_confirmation_sms: false}, _cases),
  #   do: :ok

  # defp send_confirmation_sms(
  #        socket,
  #        %CreateSchema{send_confirmation_sms: true, type: type},
  #        cases
  #      ) do
  #   locale = Gettext.get_locale(HygeiaGettext)

  #   [] =
  #     cases
  #     |> Enum.map(
  #       &Task.async(fn ->
  #         case List.last(&1.phases) do
  #           %Phase{details: %Phase.PossibleIndex{type: ^type}, quarantine_order: false} ->
  #             {:error, :no_quarantine_ordered}

  #           %Phase{details: %Phase.PossibleIndex{type: ^type}, quarantine_order: true} = phase ->
  #             Gettext.put_locale(HygeiaGettext, locale)

  #             CommunicationContext.create_outgoing_sms(&1, quarantine_sms(socket, &1, phase))

  #           %Phase{} ->
  #             {:error, :not_latest_phase}
  #         end
  #       end)
  #     )
  #     |> Enum.map(&Task.await/1)
  #     |> Enum.reject(&match?({:ok, _}, &1))
  #     |> Enum.reject(&match?({:error, :no_mobile_number}, &1))
  #     |> Enum.reject(&match?({:error, :sms_config_missing}, &1))
  #     |> Enum.reject(&match?({:error, :not_latest_phase}, &1))
  #     |> Enum.reject(&match?({:error, :no_quarantine_ordered}, &1))

  #   :ok
  # end

  def person_case(%Person{} = person) do
    person
    |> Map.get(:cases)
    |> List.first()
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

  def put_action_validate(changeset, data)
  def put_action_validate(%Ecto.Changeset{} = changeset, nil), do: changeset

  def put_action_validate(%Ecto.Changeset{} = changeset, _) do
    Map.put(changeset, :action, :validate)
  end
end
