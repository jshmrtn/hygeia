defmodule Hygeia.Jobs.SendCaseClosedEmail do
  @moduledoc """
  Send Case Closed Email
  """

  use GenServer

  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CommunicationContext
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo
  alias Hygeia.TenantContext.Tenant

  @url_generator Application.compile_env!(:hygeia, [__MODULE__, :url_generator])

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.hours(1)
  end

  defstruct []

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:case_close_email_job)

    interval_ms = Keyword.get(opts, :interval_ms, @default_refresh_interval_ms)

    Process.send_after(self(), {:start_interval, interval_ms}, :rand.uniform(interval_ms))

    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_info({:start_interval, interval_ms}, state) do
    :timer.send_interval(interval_ms, :refresh)
    send(self(), :refresh)

    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    send_emails()

    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:refresh, state) do
    send_emails()

    {:noreply, state}
  end

  @spec refresh(server :: GenServer.server()) :: :ok
  def refresh(server) do
    GenServer.cast(server, :refresh)
  end

  @spec text(phase :: Phase.t(), case :: Case.t(), message_type :: atom) :: String.t()
  defp text(%Phase{details: %Phase.Index{}} = phase, case, message_type) do
    gettext(
      """
      Dear Sir / Madam,

      Your isolation period ends tomorrow %{date}. If you did not experience any fever or coughs with sputum, you're allowed to leave isolation.

      You can find the isolation end confirmation via the following link: %{isolation_end_confirmation_link}

      To access the confirmation, please log in using you firstname & lastname. (initials: %{initial_first_name}. %{initial_last_name}.)

      Should you continue to feel ill, please contact your general practitioner.

      Kind Regards,
      %{message_signature}
      """,
      date: HygeiaCldr.Date.to_string!(Date.add(phase.end, 1), format: :full),
      isolation_end_confirmation_link: @url_generator.pdf_url(case, phase),
      message_signature: Tenant.get_message_signature_text(case.tenant, message_type),
      initial_first_name: String.slice(case.person.first_name, 0..0),
      initial_last_name: String.slice(case.person.last_name, 0..0)
    )
  end

  defp text(%Phase{details: %Phase.PossibleIndex{}} = phase, case, message_type),
    do:
      gettext(
        """
        Dear Sir / Madam,

        Your quarantine period ends tomorrow %{date}. If you do not currently experience any symptoms, you're allowed to leave quarantine.

        Should you feel ill, please contact your general practitioner.

        Kind Regards,
        %{message_signature}
        """,
        date: HygeiaCldr.Date.to_string!(Date.add(phase.end, 1), format: :full),
        message_signature: Tenant.get_message_signature_text(case.tenant, message_type)
      )

  @spec email_subject(phase :: Phase.t()) :: String.t()
  def email_subject(%Phase{details: %Phase.Index{}}),
    do: gettext("Isolation Period End")

  def email_subject(%Phase{details: %Phase.PossibleIndex{}}),
    do: gettext("Quarantine Period End")

  @spec email_body(phase :: Phase.t(), case :: Case.t()) :: String.t()
  def email_body(phase, case), do: text(phase, case, :email)

  @spec sms_text(phase :: Phase.t(), case :: Case.t()) :: String.t()
  def sms_text(phase, case), do: text(phase, case, :sms)

  defp send_emails do
    [] =
      CaseContext.list_cases_for_automated_closed_email()
      |> Enum.map(&send_close_email/1)
      |> Enum.reject(&match?({:ok, _case}, &1))
  end

  defp send_close_email({case, phase}) do
    Repo.transaction(fn ->
      # TODO: Get Local from Case
      HygeiaCldr.put_locale("de-CH")
      Gettext.put_locale(HygeiaCldr.get_locale().gettext_locale_name || "de")

      with case <- CaseContext.get_case_with_lock!(case.uuid),
           case <- Repo.preload(case, tenant: [], person: []),
           :ok <- send_sms(case, phase),
           :ok <- send_email(case, phase),
           {:ok, case} <- CaseContext.case_phase_automated_email_sent(case, phase) do
        case
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp send_sms(case, phase) do
    case
    |> CommunicationContext.create_outgoing_sms(sms_text(phase, case))
    |> case do
      {:ok, _sms} -> :ok
      {:error, :no_mobile_number} -> :ok
      {:error, :sms_config_missing} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_email(case, phase) do
    case
    |> CommunicationContext.create_outgoing_email(
      email_subject(phase),
      email_body(phase, case)
    )
    |> case do
      {:ok, _email} -> :ok
      {:error, :no_email} -> :ok
      {:error, :no_outgoing_mail_configuration} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
