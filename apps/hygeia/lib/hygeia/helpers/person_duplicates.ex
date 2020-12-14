defmodule Hygeia.Helpers.PersonDuplicates do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Hygeia.CaseContext

  @spec detect_name_duplicates(changeset :: Changeset.t()) :: Changeset.t()
  def detect_name_duplicates(changeset) do
    with first_name when is_binary(first_name) <- get_field(changeset, :first_name),
         last_name when is_binary(last_name) <- get_field(changeset, :last_name),
         [_ | _] = suspected_duplicates <-
           CaseContext.list_people_by_name(first_name, last_name) do
      add_suspected_duplicates(changeset, Enum.map(suspected_duplicates, & &1.uuid))
    else
      nil -> changeset
      [] -> changeset
    end
  end

  @spec add_suspected_duplicates(changeset :: Changeset.t(), ids :: [String.t()]) :: Changeset.t()
  def add_suspected_duplicates(changeset, ids) do
    put_change(
      changeset,
      :suspected_duplicates_uuid,
      ids
      |> Kernel.++(get_field(changeset, :suspected_duplicates_uuid) || [])
      |> Enum.uniq()
      |> Kernel.--([get_field(changeset, :uuid)])
    )
  end

  @spec detect_duplicates(
          changeset :: Changeset.t(),
          contact_method_type :: :mobile | :landline | :email
        ) :: Changeset.t()
  def detect_duplicates(changeset, contact_method_type) do
    with value when is_binary(value) <- get_field(changeset, contact_method_type),
         [_ | _] = suspected_duplicates <-
           CaseContext.list_people_by_contact_method(contact_method_type, value) do
      add_suspected_duplicates(changeset, Enum.map(suspected_duplicates, & &1.uuid))
    else
      nil -> changeset
      [] -> changeset
      _id -> changeset
    end
  end
end
