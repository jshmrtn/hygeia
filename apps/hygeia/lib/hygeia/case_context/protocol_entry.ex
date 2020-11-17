defmodule Hygeia.CaseContext.ProtocolEntry do
  @moduledoc """
  Case Protocol Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ProtocolEntry.Email
  alias Hygeia.CaseContext.ProtocolEntry.Note
  alias Hygeia.CaseContext.ProtocolEntry.Sms

  @type t :: %__MODULE__{
          uuid: String.t(),
          case_uuid: String.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          entry: Note.t() | Sms.t() | Email.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          case_uuid: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          entry: Note.t() | Sms.t() | Email.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "protocol_entries" do
    field :entry, PolymorphicEmbed,
      types: [
        note: Note,
        sms: Sms,
        email: Email
      ]

    # Use in Protocol Creation Form
    field :type, :string, virtual: true, default: "note"

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(protocol_entry :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(protocol_entry, attrs) do
    protocol_entry
    |> cast(attrs, [:case_uuid, :type])
    |> cast_polymorphic_embed(:entry)
    |> validate_required([:case_uuid, :entry])
    |> assoc_constraint(:case)
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.ProtocolEntry
    alias Hygeia.UserContext.User

    @spec authorized?(
            resource :: ProtocolEntry.t(),
            action :: :create | :list,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_protocol_entry, action, :anonymous, _meta)
        when action in [:list, :create],
        do: false

    def authorized?(_protocol_entry, action, %User{roles: roles}, _meta)
        when action in [:list, :create],
        do: :tracer in roles or :supervisor in roles or :admin in roles
  end
end
