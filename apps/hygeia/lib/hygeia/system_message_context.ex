defmodule Hygeia.SystemMessageContext do
  @moduledoc """
  The System Message context.
  """

  use Hygeia, :context

  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.SystemMessageContext.SystemMessageCache
  alias Hygeia.UserContext.User

  @doc """
  Returns the list of system_messages.

  ## Examples

      iex> list_system_messages()
      [%SystemMessage{}, ...]

  """
  @spec list_system_messages :: [SystemMessage.t()]
  def list_system_messages,
    do: Repo.all(from(system_message in SystemMessage, order_by: [desc: system_message.end_date]))

  @doc """
  Gets a single system_message.

  Raises `Ecto.NoResultsError` if the System message does not exist.

  ## Examples

      iex> get_system_message!(123)
      %SystemMessage{}

      iex> get_system_message!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_system_message!(id :: String.t()) :: SystemMessage.t()
  def get_system_message!(id), do: Repo.get!(SystemMessage, id)

  @doc """
  Creates a system_message.

  ## Examples

      iex> create_system_message(%{field: value})
      {:ok, %SystemMessage{}}

      iex> create_system_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_system_message(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, SystemMessage.t()} | {:error, Ecto.Changeset.t(SystemMessage.t())}
  def create_system_message(attrs \\ %{}) do
    %SystemMessage{}
    |> change_system_message(attrs)
    |> versioning_insert()
    |> broadcast("system_messages", :create)
    |> versioning_extract()
  end

  @doc """
  Updates a system_message.

  ## Examples

      iex> update_system_message(system_message, %{field: new_value})
      {:ok, %SystemMessage{}}

      iex> update_system_message(system_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_system_message(
          system_message :: SystemMessage.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, SystemMessage.t()} | {:error, Ecto.Changeset.t(SystemMessage.t())}
  def update_system_message(%SystemMessage{} = system_message, attrs) do
    system_message
    |> change_system_message(attrs)
    |> versioning_update()
    |> broadcast("system_messages", :update)
    |> versioning_extract()
  end

  @doc """
  Deletes a system_message.

  ## Examples

      iex> delete_system_message(system_message)
      {:ok, %SystemMessage{}}

      iex> delete_system_message(system_message)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_system_message(system_message :: SystemMessage.t()) ::
          {:ok, SystemMessage.t()} | {:error, Ecto.Changeset.t(SystemMessage.t())}
  def delete_system_message(%SystemMessage{} = system_message) do
    system_message
    |> change_system_message()
    |> versioning_delete()
    |> broadcast("system_messages", :delete)
    |> versioning_extract()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system_message changes.

  ## Examples

      iex> change_system_message(system_message)
      %Ecto.Changeset{data: %SystemMessage{}}

  """

  @spec change_system_message(
          system_message :: SystemMessage.t() | SystemMessage.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t()
  def change_system_message(%SystemMessage{} = system_message, attrs \\ %{}),
    do: SystemMessage.changeset(system_message, attrs)

  @spec list_active_system_messages(user :: User.t()) :: [system_message :: String.t()]
  def list_active_system_messages(user) do
    ets_table_name = Module.safe_concat(SystemMessageCache, Table)

    if :ets.whereis(ets_table_name) != :undefined do
      MapSet.to_list(
        for {_uuid, msg, roles, tenants} <- :ets.tab2list(ets_table_name),
            tenant_uuid <- tenants,
            role <- roles,
            User.has_role?(user, role, tenant_uuid),
            into: MapSet.new(),
            do: msg
      )
    end
  end

  @spec get_active_system_messages :: [SystemMessage.t()]
  def get_active_system_messages do
    time_now = NaiveDateTime.utc_now()

    Repo.all(
      from(system_message in SystemMessage,
        where:
          fragment(
            "? BETWEEN ? AND ?",
            ^time_now,
            system_message.start_date,
            system_message.end_date
          ),
        order_by: system_message.end_date,
        preload: [:related_tenants]
      )
    )
  end
end
