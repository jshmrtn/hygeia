defmodule Hygeia.NotificationContext.Notification.SelfServiceHelpRequest do
  @moduledoc """
  Model for Self Service Help Request Notification
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
          self_service_help_request ::
            self_service_help_request | Changeset.t(self_service_help_request),
          Hygeia.ecto_changeset_params()
        ) :: Changeset.t(self_service_help_request)
        when self_service_help_request: t | empty
  def changeset(self_service_help_request, attrs),
    do:
      self_service_help_request
      |> cast(attrs, [:case_uuid, :uuid])
      |> validate_required([:case_uuid])
end
