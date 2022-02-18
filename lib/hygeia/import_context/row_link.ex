defmodule Hygeia.ImportContext.RowLink do
  @moduledoc """
  Import Row Link Model
  """
  use Hygeia, :model

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Row

  @type empty :: %__MODULE__{
          import_uuid: Ecto.UUID.t() | nil,
          import: Ecto.Schema.belongs_to(Import.t()) | nil,
          row_uuid: Ecto.UUID.t() | nil,
          row: Ecto.Schema.belongs_to(Row.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          import_uuid: Ecto.UUID.t(),
          import: Ecto.Schema.belongs_to(Import.t()) | nil,
          row_uuid: Ecto.UUID.t(),
          row: Ecto.Schema.belongs_to(Row.t()) | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  schema "row_links" do
    belongs_to :import, Import, references: :uuid, foreign_key: :import_uuid, primary_key: true
    belongs_to :row, Row, references: :uuid, foreign_key: :row_uuid, primary_key: true

    timestamps()
  end

  @doc false
  @spec changeset(row :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t(t | empty)
  def changeset(row, attrs) do
    cast(row, attrs, [:import_uuid, :row_uuid])
  end
end
