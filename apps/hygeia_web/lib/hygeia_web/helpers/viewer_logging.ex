defmodule HygeiaWeb.Helpers.ViewerLogging do
  @moduledoc false

  def log_viewer(user, connect_info, host_uri, action, resource, resource_id \\ nil) do
    ip =
      case connect_info do
        nil -> nil
        connect_info -> connect_info.peer_data.address
      end

    message = %{
      user_uuid: user.uuid,
      time: DateTime.utc_now(),
      ip: ip,
      url: URI.to_string(host_uri),
      action: action,
      resource: resource,
      resource_id: resource_id
    }

    IO.inspect(message, label: "************ VIEWER LOGG MESSAGE ***********")
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "viewer_logging", message)
  end
end
