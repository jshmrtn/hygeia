defmodule Hygeia.AuditContext.ResourceView do
  @moduledoc """
  Resource View Record Model
  """
  use Hygeia, :model

  import EctoEnum

  alias Hygeia.EctoType.IP

  defenum Action, :resource_view_action, ["list", "details"]
  defenum AuthType, :resource_view_auth_type, ["user", "person", "anonymous"]

  @primary_key false
  schema "resource_views" do
    field :action, Action
    field :auth_subject, Ecto.UUID
    field :auth_type, AuthType
    field :ip_address, IP
    field :request_id, :integer
    field :resource_table, :string
    field :resource_pk, :map
    field :time, :utc_datetime_usec
    field :uri, :string
  end
end
