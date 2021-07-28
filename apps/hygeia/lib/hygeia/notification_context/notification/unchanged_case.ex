defmodule Hygeia.NotificationContext.Notification.UnchangedCase do
  @moduledoc """
  Model for Unchanged Case Notification
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
          unchanged_case ::
            unchanged_case | Changeset.t(unchanged_case),
          Hygeia.ecto_changeset_params()
        ) :: Changeset.t(unchanged_case)
        when unchanged_case: t | empty
  def changeset(unchanged_case, attrs) do
    unchanged_case
    |> cast(attrs, [:case_uuid, :uuid])
    |> validate_required([:case_uuid])
  end
end
