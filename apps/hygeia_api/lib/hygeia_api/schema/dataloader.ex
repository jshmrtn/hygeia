defmodule HygeiaApi.Schema.Dataloader do
  @moduledoc """
  Absinthe Dataloader
  """

  @spec data :: Dataloader.Ecto.t()
  def data, do: Dataloader.Ecto.new(Hygeia.Repo, query: &query/2)

  @spec query(Ecto.Query.t(), map) :: Ecto.Query.t()
  def query(queryable, _params), do: queryable
end
