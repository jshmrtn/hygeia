defmodule HygeiaWeb.Helpers.ViewerLogging do
  @moduledoc false

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User

  @spec log_viewer(
          request_id :: String.t(),
          auth :: User.t() | Person.t() | :anonymous,
          ip_address :: :inet.ip_address(),
          url :: String.t(),
          action :: atom,
          resource :: any
        ) :: :ok
  def log_viewer(
        request_id,
        auth,
        ip_address,
        url,
        action,
        %resource_name{} = resource
      ) do
    message = %{
      request_id: request_id,
      auth:
        case auth do
          %User{uuid: uuid} -> {User, uuid}
          %Person{uuid: uuid} -> {Person, uuid}
          :anonymous -> :anonymous
          nil -> :anonymous
        end,
      time: DateTime.utc_now(),
      ip_address: ip_address,
      url: url,
      action: action,
      resource: resource_name,
      resource_uuid: resource.uuid
    }

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "viewer_logging", message)
  end
end
