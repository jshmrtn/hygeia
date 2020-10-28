defmodule Hygeia.CaseContext.ProtocolEntry do
  @moduledoc """
  Case Protocol Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Note
  alias Hygeia.CaseContext.Sms

  @type t :: %__MODULE__{
          uuid: String.t(),
          case_uuid: String.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          entry: Note.t() | Sms.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          case_uuid: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          entry: Note.t() | Sms.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "protocol_entries" do
    field :entry, PolymorphicEmbed,
      types: [
        note: Note,
        sms: Sms
      ]

    # Use in Protocol Creation Form
    field :type, :string, virtual: true, default: "note"

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(protocol_entry :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(protocol_entry, attrs) do
    protocol_entry
    |> cast(attrs, [:case_uuid, :type])
    |> cast_polymorphic_embed(:entry)
    |> validate_required([:case_uuid, :entry])
    |> assoc_constraint(:case)
  end
end
