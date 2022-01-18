defmodule Hygeia.LoginRateLimiter do
  @moduledoc """
  Person Login Rate Limiter
  """

  use DynamicSupervisor

  alias Hygeia.LoginRateLimiter.Worker

  @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
  def start_link(opts),
    do:
      DynamicSupervisor.start_link(__MODULE__, Keyword.take(opts, []),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl DynamicSupervisor
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec handle_login(
          person_uuid :: Ecto.UUID.t(),
          callback :: (() -> {success :: boolean, result}),
          server_args :: Keyword.t()
        ) ::
          {:ok, result} | {:error, :locked}
        when result: term
  def handle_login(person_uuid, callback, server_args \\ []) do
    case DynamicSupervisor.start_child(
           __MODULE__,
           {Worker, Keyword.put_new(server_args, :person_uuid, person_uuid)}
         ) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      :ignore -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    GenStateMachine.call({:global, {Worker, person_uuid}}, {:login, callback})
  end

  @spec locked?(person_uuid :: Ecto.UUID.t()) :: boolean
  def locked?(person_uuid) do
    GenStateMachine.call({:global, {Worker, person_uuid}}, :locked?)
  catch
    :exit, {:noproc, {:gen_statem, :call, [{:global, {Worker, ^person_uuid}} | _args]}} ->
      false
  end
end
