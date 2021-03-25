defmodule Hygeia.Authorization do
  @moduledoc """
  Check if a user is authorized to do an action
  """

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User

  defprotocol Resource do
    @spec preload(resource :: term) :: term
    def preload(resource)

    @spec authorized?(
            resource :: term,
            action :: atom,
            user :: :anonymous | User.t() | Person.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(resource, action, user, meta)
  end

  @spec authorized?(
          resource :: term | atom,
          action :: atom,
          user :: :anonymous | User.t() | Person.t(),
          meta :: %{atom() => term} | [{atom, term}]
        ) :: boolean
  def authorized?(resource, action, user \\ :anonymous, meta \\ %{})

  def authorized?(resource, action, user, meta) when is_list(meta),
    do: authorized?(resource, action, user, Map.new(meta))

  def authorized?(resource, action, user, %{} = meta) when is_atom(resource),
    do: authorized?(struct(resource), action, user, meta)

  def authorized?(resource, action, user, %{} = meta) when is_atom(action) do
    resource
    |> Resource.preload()
    |> Resource.authorized?(action, user, meta)
  end
end
