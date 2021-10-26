defmodule Hygeia.NotificationContext do
  @moduledoc """
  The NotificationContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Case
  alias Hygeia.NotificationContext.Notification
  alias Hygeia.UserContext.User

  @doc """
  Returns the list of notifications.

  ## Examples

      iex> list_notifications()
      [%Notification{}, ...]

  """
  @spec list_notifications :: [Notification.t()]
  def list_notifications, do: Repo.all(Notification)

  @spec list_notifications(user :: User.t()) :: [Notification.t()]
  def list_notifications(user),
    do:
      Repo.all(
        from(notification in Ecto.assoc(user, :notifications),
          order_by: [desc: notification.inserted_at, desc: notification.uuid]
        )
      )

  @spec list_and_lock_users_with_pending_notification_reminders :: [User.t()]
  def list_and_lock_users_with_pending_notification_reminders,
    do:
      Repo.all(
        from(user in User,
          where:
            user.uuid in subquery(
              from(notification in Notification,
                where: not notification.read and not notification.notified,
                join: notification_user in assoc(notification, :user),
                join: tenant in assoc(notification_user, :tenants),
                select: notification_user.uuid,
                group_by: notification_user.uuid
              )
            ),
          lock: "FOR UPDATE"
        )
      )

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_notification!(id :: Ecto.UUID.t()) :: Notification.t()
  def get_notification!(id), do: Repo.get!(Notification, id)

  @spec get_notification_by_type_and_case(type :: String.t(), case :: Case.t()) ::
          Notification.t() | nil
  def get_notification_by_type_and_case(type, case),
    do:
      Repo.one(
        from(notification in Notification,
          where:
            fragment("?->>'__type__'", notification.body) == ^type and
              fragment("?->>'case_uuid'", notification.body) == ^case.uuid
        )
      )

  @doc """
  Creates a notification.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_notification(user :: User.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t(Notification.t())}
  def create_notification(%User{} = user, attrs \\ %{}),
    do:
      user
      |> Ecto.build_assoc(:notifications)
      |> change_notification(attrs)
      |> versioning_insert()
      # Notification triggered via Hygeia.PostgresPubSubRelay
      |> versioning_extract()

  @doc """
  Updates a notification.

  ## Examples

      iex> update_notification(notification, %{field: new_value})
      {:ok, %Notification{}}

      iex> update_notification(notification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_notification(
          notification :: Notification.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: {:ok, Notification.t()} | {:error, Ecto.Changeset.t(Notification.t())}
  def update_notification(%Notification{} = notification, attrs),
    do:
      notification
      |> change_notification(attrs)
      |> versioning_update()
      |> broadcast("notifications", :update, & &1.uuid, &["notifications:users:#{&1.user_uuid}"])
      |> versioning_extract()

  @spec mark_all_as_read(user :: User.t()) :: :ok
  def mark_all_as_read(%User{uuid: user_uuid} = user) do
    {:ok, %{result: {length, nil}}} =
      Ecto.Multi.new()
      |> Ecto.Multi.update_all(:result, Ecto.assoc(user, :notifications), set: [read: true])
      |> authenticate_multi()
      |> Repo.transaction()

    if length > 0 do
      Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications", :read_all)
      Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications:users:#{user_uuid}", :read_all)
    end

    :ok
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_notification(notification :: Notification.t()) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t(Notification.t())}
  def delete_notification(%Notification{} = notification),
    do:
      notification
      |> change_notification()
      |> versioning_delete()
      |> broadcast("notifications", :delete, & &1.uuid, &["notifications:users:#{&1.user_uuid}"])
      |> versioning_extract()

  @spec delete_all_notifications(user :: User.t()) :: :ok
  def delete_all_notifications(%User{uuid: user_uuid} = user) do
    {:ok, %{result: {length, nil}}} =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:result, Ecto.assoc(user, :notifications))
      |> authenticate_multi()
      |> Repo.transaction()

    if length > 0 do
      Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications", :deleted_all)
      Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications:users:#{user_uuid}", :deleted_all)
    end

    :ok
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  @spec change_notification(
          notification :: Notification.t() | Notification.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(Notification.t())
  def change_notification(%Notification{} = notification, attrs \\ %{}),
    do: Notification.changeset(notification, attrs)
end
