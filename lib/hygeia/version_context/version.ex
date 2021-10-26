defmodule Hygeia.VersionContext.Version do
  @moduledoc """
  Model for Versions
  """

  use Hygeia, :model

  alias Hygeia.UserContext.User
  alias Hygeia.VersionContext.Version.Event
  alias Hygeia.VersionContext.Version.Origin

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          event: Event.t(),
          item_changes: map,
          origin: Origin.t(),
          item_pk: map,
          item_table: String.t(),
          user: Ecto.Schema.belongs_to(User.t()),
          originator_id: Ecto.UUID.t(),
          inserted_at: DateTime.t()
        }

  schema "versions" do
    field :event, Event
    field :item_changes, :map
    field :origin, Origin
    field :item_pk, :map
    field :item_table, :string

    belongs_to :user, User, references: :uuid, foreign_key: :originator_id

    timestamps(updated_at: false)
  end
end
