defmodule Hygeia.Jobs.SendCaseClosedEmail do
  @moduledoc """
  Send Case Closed Email
  """

  use GenServer

  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CommunicationContext
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

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

  @impl GenServer
  def handle_cast(:refresh, state) do
    send_emails()

    {:noreply, state}
  end

  @spec refresh(server :: GenServer.server()) :: :ok
  def refresh(server) do
    GenServer.cast(server, :refresh)
  end

  @spec text(phase :: Phase.t()) :: String.t()
  defp text(%Phase{details: %Phase.Index{}}),
    do:
      gettext("""
      Dear Sir / Madam,

      Your isolation period ends tomorrow. If you did not experience any fever or coughs with sputum, you're allowed to leave isolation.

      Should you continue to feel ill, please contact your general practitioner.

      Kind Regards,
      Contact Tracing St.Gallen, Appenzell Innerrhoden, Appenzell Ausserrhoden Kantonaler Führungsstab: KFS
      """)

  defp text(%Phase{details: %Phase.PossibleIndex{}}),
    do:
      gettext("""
      Dear Sir / Madam,

      Your quarantine period ends tomorrow. If you do not currently experience any symptoms, you're allowed to leave quarantine.

      Should you feel ill, please contact your general practitioner.

      Kind Regards,
      Contact Tracing St.Gallen, Appenzell Innerrhoden, Appenzell Ausserrhoden Kantonaler Führungsstab: KFS
      """)

  @spec email_subject(phase :: Phase.t()) :: String.t()
  def email_subject(%Phase{details: %Phase.Index{}}),
    do: gettext("Isolation Period End")

  def email_subject(%Phase{details: %Phase.PossibleIndex{}}),
    do: gettext("Quarantine Period End")

  @spec email_body(phase :: Phase.t()) :: String.t()
  def email_body(phase), do: text(phase)

  @spec sms_text(phase :: Phase.t()) :: String.t()
  def sms_text(phase), do: text(phase)

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
      Gettext.put_locale(HygeiaCldr.get_locale().gettext_locale_name)

      with case <- CaseContext.get_case_with_lock!(case.uuid),
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
    |> CommunicationContext.create_outgoing_sms(sms_text(phase))
    |> case do
      {:ok, _sms} -> :ok
      {:error, :no_mobile_number} -> :ok
      {:error, :sms_config_missing} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp send_email(case, phase) do
    case
    |> CommunicationContext.create_outgoing_email(email_subject(phase), email_body(phase))
    |> case do
      {:ok, _email} -> :ok
      {:error, :no_email} -> :ok
      {:error, :no_outgoing_mail_configuration} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
