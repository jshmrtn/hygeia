defmodule HygeiaWeb.CaseLive.Create.CreateSchema do
  @moduledoc false

  alias Hygeia.CaseContext.ExternalReference

  @spec merge_assignee(
          changeset :: Ecto.Changeset.t(),
          type :: atom,
          uuid :: String.t(),
          default_uuid :: String.t()
        ) :: Ecto.Changeset.t()
  def merge_assignee(changeset, type, uuid, default_uuid)

  def merge_assignee(changeset, type, nil, default_uuid),
    do: Ecto.Changeset.put_change(changeset, type, default_uuid)

  def merge_assignee(changeset, type, uuid, _default_uuid),
    do: Ecto.Changeset.put_change(changeset, type, uuid)

  @spec merge_external_reference(changeset :: Ecto.Changeset.t(), type :: atom, id :: String.t()) ::
          Ecto.Changeset.t()
  def merge_external_reference(changeset, type, id)
  def merge_external_reference(changeset, _type, nil), do: changeset

  def merge_external_reference(changeset, type, id) do
    existing_external_references = Ecto.Changeset.fetch_field!(changeset, :external_references)

    if Enum.any?(
         existing_external_references,
         &match?(%ExternalReference{type: ^type, value: ^id}, &1)
       ) do
      changeset
    else
      Ecto.Changeset.put_embed(changeset, :external_references, [
        %{type: type, value: id} | existing_external_references
      ])
    end
  end
end
