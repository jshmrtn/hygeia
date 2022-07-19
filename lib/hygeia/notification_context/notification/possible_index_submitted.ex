defmodule Hygeia.NotificationContext.Notification.PossibleIndexSubmitted do
  @moduledoc """
  Model for Case Possible Index Submission Notification
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission

  @type empty :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          possible_index_submission: Ecto.Schema.belongs_to(PossibleIndexSubmission.t()) | nil,
          possible_index_submission_uuid: Ecto.UUID.t() | nil
        }

  @type t :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          possible_index_submission: Ecto.Schema.belongs_to(PossibleIndexSubmission.t()),
          possible_index_submission_uuid: Ecto.UUID.t()
        }

  @primary_key false
  embedded_schema do
    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    belongs_to :possible_index_submission, PossibleIndexSubmission,
      references: :uuid,
      foreign_key: :possible_index_submission_uuid
  end
end
