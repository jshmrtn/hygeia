defmodule Hygeia.NotificationContext.Notification do
  @moduledoc """
  Model for Notification
  """

  use Hygeia, :model

  alias Hygeia.UserContext.User

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          body:
            __MODULE__.CaseAssignee.t()
            | __MODULE__.EmailSendFailed.t()
            | __MODULE__.PossibleIndexSubmitted.t()
            | nil,
          notified: boolean | nil,
          read: boolean | nil,
          user: Ecto.Schema.belongs_to(User.t()) | nil,
          user_uuid: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          body:
            __MODULE__.CaseAssignee.t()
            | __MODULE__.EmailSendFailed.t()
            | __MODULE__.PossibleIndexSubmitted.t(),
          notified: boolean,
          read: boolean,
          user: Ecto.Schema.belongs_to(User.t()),
          user_uuid: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "notifications" do
    field :body, PolymorphicEmbed,
      types: [
        case_assignee: __MODULE__.CaseAssignee,
        email_send_failed: __MODULE__.EmailSendFailed,
        possible_index_submitted: __MODULE__.PossibleIndexSubmitted
      ],
      on_replace: :update

    field :notified, :boolean, default: false
    field :read, :boolean, default: false

    belongs_to :user, User, references: :uuid, foreign_key: :user_uuid

    timestamps()
  end

  @spec changeset(
          notification :: notification | Changeset.t(notification),
          Hygeia.ecto_changeset_params()
        ) :: Changeset.t(notification)
        when notification: t | empty
  def changeset(notification, attrs),
    do:
      notification
      |> cast(attrs, [:read, :notified])
      |> validate_required([:user_uuid, :read, :notified])
      |> cast_polymorphic_embed(:body)
end
