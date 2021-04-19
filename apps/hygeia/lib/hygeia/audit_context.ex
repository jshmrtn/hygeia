defmodule Hygeia.AuditContext do
  @moduledoc """
  The AuditContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User

  @spec log_view(
          request_id :: String.t(),
          auth :: User.t() | Person.t() | :anonymous,
          ip_address :: :inet.ip_address(),
          uri :: String.t(),
          action :: atom,
          resource :: any
        ) :: :ok
  def log_view(request_id, auth, ip_address, uri, action, resource) do
    Phoenix.PubSub.local_broadcast(Hygeia.PubSub, __log_topic__(), %{
      request_id: :erlang.crc32(request_id),
      auth_type:
        case auth do
          %User{} -> :user
          %Person{} -> :person
          :anonymous -> :anonymous
          nil -> :anonymous
        end,
      auth_subject:
        case auth do
          %User{uuid: uuid} -> uuid
          %Person{uuid: uuid} -> uuid
          :anonymous -> nil
          nil -> nil
        end,
      time: DateTime.utc_now(),
      ip_address: ip_address,
      uri: uri,
      action: action,
      resource_table: resource_table(resource),
      resource_pk: resource_pk(resource)
    })
  end

  defp resource_pk(%resource_name{} = resource),
    do: Map.take(resource, resource_name.__schema__(:primary_key))

  defp resource_table(%resource_name{}), do: resource_name.__schema__(:source)

  @doc false
  @spec __log_topic__ :: String.t()
  def __log_topic__, do: "__#{__MODULE__}:log_view"
end
