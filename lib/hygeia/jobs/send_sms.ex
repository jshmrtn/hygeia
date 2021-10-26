defmodule Hygeia.Jobs.SendSMS do
  @moduledoc """
  Send / Spool Emails
  """

  use GenServer

  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @default_send_interval_ms (case(Mix.env()) do
                               :dev -> :timer.seconds(30)
                               _env -> :timer.minutes(5)
                             end)

  defstruct []

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(
        __MODULE__,
        Keyword.take(opts, [:send_interval_ms]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:sms_sender)

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "sms")

    send_interval_ms = Keyword.get(opts, :send_interval_ms, @default_send_interval_ms)

    Process.send_after(
      self(),
      {:start_interval, :send, send_interval_ms},
      :rand.uniform(send_interval_ms)
    )

    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_info({:start_interval, type, interval_ms}, state) do
    :timer.send_interval(interval_ms, type)
    send(self(), type)

    {:noreply, state}
  end

  def handle_info({:created, %SMS{}, _version}, state) do
    send(self(), :send)

    {:noreply, state}
  end

  def handle_info({:updated, %SMS{}, _version}, state), do: {:noreply, state}
  def handle_info({:deleted, %SMS{}, _version}, state), do: {:noreply, state}

  def handle_info(:send, state) do
    Repo.transaction(fn ->
      Hygeia.Jobs.TaskSupervisor
      |> Task.Supervisor.async_stream(
        CommunicationContext.list_sms_to_send(),
        &send(&1),
        max_concurrency: 10,
        ordered: false
      )
      |> Enum.reduce(Ecto.Multi.new(), fn
        {:ok, {%SMS{uuid: uuid} = sms, new_status, delivery_receipt_id}}, acc ->
          Ecto.Multi.run(acc, uuid, fn _repo, _before ->
            CommunicationContext.update_sms(sms, %{
              status: new_status,
              delivery_receipt_id: delivery_receipt_id
            })
          end)
      end)
      |> Repo.transaction()
    end)

    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  @spec send(sms :: SMS.t()) :: {SMS.t(), SMS.Status.t(), String.t()}
  defp send(
         %SMS{
           tenant: %{outgoing_sms_configuration: outgoing_sms_configuration}
         } = sms
       ) do
    {status, delivery_receipt_id} = Hygeia.SmsSender.send(outgoing_sms_configuration, sms)
    {sms, status, delivery_receipt_id}
  end
end
