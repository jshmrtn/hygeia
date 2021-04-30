defmodule Hygeia.NotificationContext.Notification.CaseAssignee do
  @moduledoc """
  Model for Case Assignee Notification
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case

  @type empty :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil
        }

  @type t :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t()
        }

  embedded_schema do
    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
  end

  @spec changeset(
          case_assignee :: case_assignee | Changeset.t(case_assignee),
          Hygeia.ecto_changeset_params()
        ) :: Changeset.t(case_assignee)
        when case_assignee: t | empty
  def changeset(case_assignee, attrs),
    do:
      case_assignee
      |> cast(attrs, [:case_uuid])
      |> validate_required([:case_uuid])
end
