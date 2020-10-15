defmodule Hygeia.Helpers.Id do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset

  @spec fill_uuid(changeset :: Changeset.t()) :: Changeset.t()
  def fill_uuid(changeset) do
    changeset
    |> fetch_field!(:uuid)
    |> case do
      nil -> put_change(changeset, :uuid, Ecto.UUID.generate())
      uuid when is_binary(uuid) -> changeset
    end
  end

  @spec fill_human_readable_id(changeset :: Changeset.t()) :: Changeset.t()
  def fill_human_readable_id(changeset) do
    {:ok, new_id} =
      changeset
      |> fetch_field!(:uuid)
      |> HumanReadableIdentifierGenerator.fetch_human_readable_id()

    changeset
    |> fetch_field!(:human_readable_id)
    |> case do
      ^new_id -> changeset
      _other_id -> put_change(changeset, :human_readable_id, new_id)
    end
  end
end
