defmodule HygeiaWeb.CaseLive.CaseLiveHelper do
  @moduledoc false

  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  @spec get_users(
          users :: [User.t()],
          tenant_uuid :: String.t() | nil,
          role :: UserContext.Grant.Role.t()
        ) :: [User.t()]
  def get_users(users, nil, _role), do: users

  def get_users(users, tenant_uuid, role),
    do: Enum.filter(users, &User.has_role?(&1, role, tenant_uuid))
end
