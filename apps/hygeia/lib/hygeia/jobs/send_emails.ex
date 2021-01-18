defmodule Hygeia.Jobs.SendEmails do
  @moduledoc """
  Send / Spool Emails
  """

  use GenServer

  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @default_send_interval_ms (case(Mix.env()) do
                               :dev -> :timer.seconds(30)
                               _env -> :timer.minutes(5)
                             end)
  @default_abort_interval_ms (case(Mix.env()) do
                                :dev -> :timer.seconds(30)
                                _env -> :timer.hours(1)
                              end)

  defstruct []

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(
        __MODULE__,
        Keyword.take(opts, [:send_interval_ms, :abort_interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:email_sender)

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "emails")

    send_interval_ms = Keyword.get(opts, :send_interval_ms, @default_send_interval_ms)

    abort_interval_ms = Keyword.get(opts, :abort_interval_ms, @default_abort_interval_ms)

    Process.send_after(
      self(),
      {:start_interval, :send, send_interval_ms},
      :rand.uniform(send_interval_ms)
    )

    Process.send_after(
      self(),
      {:start_interval, :abort, abort_interval_ms},
      :rand.uniform(abort_interval_ms)
    )

    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_info({:start_interval, type, interval_ms}, state) do
    :timer.send_interval(interval_ms, type)
    send(self(), type)

    {:noreply, state}
  end

  def handle_info(:abort, state) do
    Repo.transaction(fn ->
      {:ok, _results} =
        CommunicationContext.list_emails_to_abort()
        |> Enum.reduce(Ecto.Multi.new(), fn %Email{uuid: uuid} = email, acc ->
          Ecto.Multi.run(acc, uuid, fn _repo, _before ->
            CommunicationContext.update_email(email, %{status: :retries_exceeded})
          end)
        end)
        |> Repo.transaction()
    end)

    {:noreply, state}
  end

  def handle_info({:created, %Email{}, _version}, state) do
    send(self(), :send)

    {:noreply, state}
  end

  def handle_info({:updated, %Email{}, _version}, state), do: {:noreply, state}
  def handle_info({:deleted, %Email{}, _version}, state), do: {:noreply, state}

  def handle_info(:send, state) do
    Repo.transaction(fn ->
      Hygeia.Jobs.TaskSupervisor
      |> Task.Supervisor.async_stream(
        CommunicationContext.list_emails_to_send(),
        &send(&1),
        max_concurrency: 10,
        ordered: false
      )
      |> Enum.reduce(Ecto.Multi.new(), fn {:ok,
                                           {%Email{uuid: uuid} = email, retried_at, new_status}},
                                          acc ->
        Ecto.Multi.run(acc, uuid, fn _repo, _before ->
          CommunicationContext.update_email(email, %{status: new_status, last_try: retried_at})
        end)
      end)
      |> Repo.transaction()
    end)

    {:noreply, state}
  end

  @spec send(email :: Email.t()) :: {Email.t(), DateTime.t(), Email.Status.t()}

  case Mix.env() do
    :prod ->
      defp send(
             %Email{
               tenant: %{outgoing_mail_configuration: outgoing_mail_configuration}
             } = email
           ) do
        {email, DateTime.utc_now(), Hygeia.EmailSender.send(outgoing_mail_configuration, email)}
      end

    _env ->
      defp send(%Email{message: message} = email) do
        require Logger

        Logger.info("""
        Email Sent:

        #{message}
        """)

        {email, DateTime.utc_now(), :success}
      end
  end
end
