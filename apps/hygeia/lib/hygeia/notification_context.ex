defmodule Hygeia.NotificationContext do
  @moduledoc """
  The NotificationContext context.
  """

  use Hygeia, :context

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

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_notification!(id :: String.t()) :: Notification.t()
  def get_notification!(id), do: Repo.get!(Notification, id)

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
    {_length, nil} =
      user
      |> Ecto.assoc(:notifications)
      |> Repo.update_all(set: [read: true])

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications", :read_all)
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications:users:#{user_uuid}", :read_all)

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
    {_length, nil} =
      user
      |> Ecto.assoc(:notifications)
      |> Repo.delete_all()

    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications", :deleted_all)
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, "notifications:users:#{user_uuid}", :deleted_all)

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
