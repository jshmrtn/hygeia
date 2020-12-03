defmodule HygeiaUserSync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias HygeiaIam.ServiceUserToken

  # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
  user_sync_token_server_name = {:global, Module.concat(ServiceUserToken, UserSync)}

  case Mix.env() do
    :test ->
      @jobs []

    _env ->
      @jobs [
        {Highlander, {ServiceUserToken, user: :user_sync, name: user_sync_token_server_name}},
        {Highlander, {HygeiaUserSync, user_sync_token_server_name: user_sync_token_server_name}}
      ]
  end

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(
      @jobs,
      strategy: :rest_for_one,
      name: HygeiaUserSync.Supervisor
    )
  end
end
