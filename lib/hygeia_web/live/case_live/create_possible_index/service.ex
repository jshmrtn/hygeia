defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.Service do
  @moduledoc false

  import Ecto.Changeset
  import HygeiaWeb.Helpers.Confirmation
  import HygeiaWeb.Helpers.Changeset

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Transmission

  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS

  alias Hygeia.Repo

  @spec upsert(form_data :: map()) :: {:ok, any()} | {:error, atom()}
  def upsert(form_data) do
    success =
      Repo.transaction(fn ->
        Enum.map(form_data.bindings, fn %{
                                          person_changeset: person_changeset,
                                          case_changeset: case_changeset
                                        } ->
          if not existing_entity?(person_changeset) do
            {:ok, _person} = CaseContext.create_person(person_changeset)
          end

          case =
            if existing_entity?(case_changeset) do
              {:ok, case} = CaseContext.update_case(case_changeset)
              case
            else
              {:ok, case} = CaseContext.create_case(case_changeset)
              case
            end

          {:ok, _} = insert_transmission(case, form_data)
        end)
      end)

    case success do
      {:ok, results} -> {:ok, results}
      _errors -> {:error, :transaction_failed}
    end
  end

  @spec send_confirmations(
          socket :: Phoenix.LiveView.Socket.t(),
          bindings :: [map()] | [],
          transmission_type :: atom()
        ) :: :ok
  def send_confirmations(socket, bindings, transmission_type)

  def send_confirmations(socket, bindings, :contact_person) when is_list(bindings) do
    Enum.each(bindings, fn
      %{person_changeset: person_changeset, case_changeset: case_changeset, reporting: reporting} ->
        email_addresses =
          person_changeset
          |> fetch_field!(:contact_methods)
          |> Enum.filter(&(&1.type == :email and &1.uuid in reporting))
          |> Enum.map(& &1.value)

        phone_numbers =
          person_changeset
          |> fetch_field!(:contact_methods)
          |> Enum.filter(&(&1.type == :mobile and &1.uuid in reporting))
          |> Enum.map(& &1.value)

        [] =
          fn ->
            send_confirmation_emails(
              socket,
              apply_changes(case_changeset),
              email_addresses,
              :contact_person
            )
          end
          |> Task.async()
          |> Task.await()
          |> Enum.reject(&match?({:ok, _}, &1))
          |> Enum.reject(&match?({:error, :no_outgoing_mail_configuration}, &1))
          |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

        [] =
          fn ->
            send_confirmation_sms(
              socket,
              apply_changes(case_changeset),
              phone_numbers,
              :contact_person
            )
          end
          |> Task.async()
          |> Task.await()
          |> Enum.reject(&match?({:ok, _}, &1))
          |> Enum.reject(&match?({:error, :sms_config_missing}, &1))
          |> Enum.reject(&match?({:error, :not_latest_phase}, &1))
          |> Enum.reject(&match?({:error, :no_quarantine_ordered}, &1))

      binding ->
        binding
    end)
  end

  def send_confirmations(_socket, _tuples, _other_transmission_type), do: :ok

  @spec send_confirmation_emails(
          socket :: Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          email_addresses :: [String.t()],
          transmission_type :: atom
        ) ::
          [{:ok, Email.t()}]
          | [
              {:error,
               :not_latest_phase
               | Ecto.Changeset.t(Email.t())
               | :no_email
               | :no_outgoing_mail_configuration}
            ]
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

        Enum.map(
          email_addresses,
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

  @spec send_confirmation_sms(
          socket :: Phoenix.LiveView.Socket.t(),
          case :: Case.t(),
          phone_numbers :: [String.t()],
          transmission_type :: atom
        ) ::
          [{:ok, SMS.t()}]
          | [
              {:error,
               :no_quarantine_ordered
               | :not_latest_phase
               | Ecto.Changeset.t(SMS.t())
               | :sms_config_missing}
            ]
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

        Enum.map(
          phone_numbers,
          &CommunicationContext.create_outgoing_sms(case, &1, quarantine_sms(socket, case, phase))
        )

      %Phase{} ->
        [{:error, :not_latest_phase}]
    end
  end

  @spec insert_transmission(case :: Case.t(), map :: map()) :: {:ok, Transmission.t()}
  def insert_transmission(case, transmission_data) do
    date = transmission_data[:date]
    comment = transmission_data[:comment]
    infection_place = transmission_data[:infection_place]
    propagator_internal = transmission_data[:propagator_internal]
    propagator_ism_id = transmission_data[:propagator_ism_id]
    propagator_case_uuid = transmission_data[:propagator_case_uuid]

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

  @spec phase_dates(Date.t()) :: {Date.t(), Date.t()}
  def phase_dates(contact_date) do
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

  @spec unstruct(map()) :: map()
  defp unstruct(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, unstruct(value)} end)
    |> Map.new()
  end

  defp unstruct(list) when is_list(list), do: Enum.map(list, &unstruct/1)

  defp unstruct(other), do: other
end
