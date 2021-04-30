defmodule Hygeia.VersionContext do
  @moduledoc """
  The VersionContext context.
  """

  use Hygeia, :context

  alias Hygeia.VersionContext.Version

  @spec get_versions(schema :: atom, id :: Ecto.UUID.t()) :: [Version.t()]
  def get_versions(schema, id) do
    Repo.all(
      from(
        version in Version,
        where:
          version.item_table == ^schema.__schema__(:source) and version.item_pk == ^%{uuid: id},
        order_by: version.inserted_at
      )
    )
  end
end
