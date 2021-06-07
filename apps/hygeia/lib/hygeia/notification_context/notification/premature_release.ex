defmodule Hygeia.NotificationContext.Notification.PrematureRelease do
  @moduledoc """
  Model for Premature Release Notification
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.PrematureRelease

  @type empty :: %__MODULE__{
          premature_release: Ecto.Schema.belongs_to(PrematureRelease.t()) | nil,
          premature_release_uuid: Ecto.UUID.t() | nil
        }

  @type t :: %__MODULE__{
          premature_release: Ecto.Schema.belongs_to(PrematureRelease.t()),
          premature_release_uuid: Ecto.UUID.t()
        }

  embedded_schema do
    belongs_to :premature_release, PrematureRelease,
      references: :uuid,
      foreign_key: :premature_release_uuid
  end
end
