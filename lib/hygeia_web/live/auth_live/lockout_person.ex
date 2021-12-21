defmodule HygeiaWeb.AuthLive.LockoutPerson do
  @moduledoc false

  use GenServer

  case Mix.env() do
    :dev ->
      @initial_timeout 500
      @timeout_multiplication_factor 2
      @minimal_terminate_timeout :timer.seconds(10)

    _env ->
      @initial_timeout :timer.seconds(1)
      @timeout_multiplication_factor 4
      @minimal_terminate_timeout :timer.minutes(1)
  end

  def handle_failed_login(person_uuid) do
    person_uuid
    |> :global.whereis_name()
    |> case do
      :undefined ->
        {:ok, _process} = GenServer.start_link(__MODULE__, [], name: {:global, person_uuid})

      pid ->
        Process.send(pid, :login_failure, [])
    end
  end

  @impl GenServer
  def init(_state) do
    Process.send(self(), :login_failure, [])

    {:ok, %{timeout: @initial_timeout}}
  end

  @impl GenServer
  def handle_info(:login_failure, %{timeout: timeout} = _state) do
    terminate_timeout =
      if timeout < @minimal_terminate_timeout do
        @minimal_terminate_timeout
      else
        timeout
      end

    {:noreply, %{timeout: timeout * @timeout_multiplication_factor}, terminate_timeout}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end
