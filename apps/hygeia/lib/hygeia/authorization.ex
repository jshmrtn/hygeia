defmodule Hygeia.Authorization do
  @moduledoc """
  Check if a user is authorized to do an action
  """

  alias Hygeia.UserContext.User

  defprotocol UserContext do
    @spec user(context :: term) :: :anonymous | User.t()
    def user(context)
  end

  defimpl UserContext, for: User do
    def user(user), do: user
  end

  defimpl UserContext, for: Atom do
    def user(:anonymous), do: :anonymous
  end

  defprotocol Resource do
    @spec preload(resource :: term) :: term
    def preload(resource)

    @spec authorized?(
            resource :: term,
            action :: atom,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(resource, action, user, meta)
  end

  @spec authorized?(
          resource :: term | atom,
          action :: atom,
          user_context :: term,
          meta :: %{atom() => term} | [{atom, term}]
        ) :: boolean
  def authorized?(resource, action, user_context \\ :anonymous, meta \\ %{})

  def authorized?(resource, action, user_context, meta) when is_list(meta),
    do: authorized?(resource, action, user_context, Map.new(meta))

  def authorized?(resource, action, user_context, %{} = meta) when is_atom(resource),
    do: authorized?(struct(resource), action, user_context, meta)

  def authorized?(resource, action, user_context, %{} = meta) when is_atom(action) do
    resource
    |> Resource.preload()
    |> Resource.authorized?(action, UserContext.user(user_context), meta)
  end
end
