defmodule HygeiaUserSync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  case Mix.env() do
    :test ->
      @jobs []

    _env ->
      @jobs [
        {Highlander, HygeiaUserSync}
      ]
  end

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(
      @jobs,
      strategy: :one_for_one,
      name: HygeiaUserSync.Supervisor
    )
  end
end
