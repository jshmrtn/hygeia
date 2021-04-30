defmodule Hygeia.NotificationContext.Notification.EmailSendFailed do
  @moduledoc """
  Model for Case Email Send Failed Notification
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CommunicationContext.Email

  @type empty :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          email: Ecto.Schema.belongs_to(Email.t()) | nil,
          email_uuid: Ecto.UUID.t() | nil
        }

  @type t :: %__MODULE__{
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          email: Ecto.Schema.belongs_to(Email.t()),
          email_uuid: Ecto.UUID.t()
        }

  embedded_schema do
    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
    belongs_to :email, Email, references: :uuid, foreign_key: :email_uuid
  end
end
