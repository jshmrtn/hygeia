defmodule Hygeia.MutationContext do
  @moduledoc """
  The MutationContext context.
  """

  use Hygeia, :context

  alias Hygeia.MutationContext.Mutation

  @doc """
  Returns the list of mutations.

  ## Examples

      iex> list_mutations()
      [%Mutation{}, ...]

  """
  @spec list_mutations :: [Mutation.t()]
  def list_mutations, do: Repo.all(Mutation)

  @doc """
  Gets a single mutation.

  Raises `Ecto.NoResultsError` if the Mutation does not exist.

  ## Examples

      iex> get_mutation!(123)
      %Mutation{}

      iex> get_mutation!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_mutation!(id :: Ecto.UUID.t()) :: Mutation.t()
  def get_mutation!(id), do: Repo.get!(Mutation, id)

  @spec get_mutation_by_ism_code(ism_code :: integer()) :: Mutation.t() | nil
  def get_mutation_by_ism_code(ism_code)
      when is_integer(ism_code),
      do: Repo.get_by(Mutation, ism_code: ism_code)

  @doc """
  Creates a mutation.

  ## Examples

      iex> create_mutation(%{field: value})
      {:ok, %Mutation{}}

      iex> create_mutation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_mutation(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Mutation.t()} | {:error, Ecto.Changeset.t(Mutation.t())}
  def create_mutation(attrs \\ %{}),
    do:
      %Mutation{}
      |> change_mutation(attrs)
      |> versioning_insert()
      |> broadcast("mutations", :create)
      |> versioning_extract()

  @doc """
  Updates a mutation.

  ## Examples

      iex> update_mutation(mutation, %{field: new_value})
      {:ok, %Mutation{}}

      iex> update_mutation(mutation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_mutation(
          mutation :: Mutation.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, Mutation.t()} | {:error, Ecto.Changeset.t(Mutation.t())}
  def update_mutation(%Mutation{} = mutation, attrs),
    do:
      mutation
      |> change_mutation(attrs)
      |> versioning_update()
      |> broadcast("mutations", :update)
      |> versioning_extract()

  @doc """
  Deletes a mutation.

  ## Examples

      iex> delete_mutation(mutation)
      {:ok, %Mutation{}}

      iex> delete_mutation(mutation)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_mutation(mutation :: Mutation.t()) ::
          {:ok, Mutation.t()} | {:error, Ecto.Changeset.t(Mutation.t())}
  def delete_mutation(%Mutation{} = mutation),
    do:
      mutation
      |> change_mutation()
      |> versioning_delete()
      |> broadcast("mutations", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mutation changes.

  ## Examples

      iex> change_mutation(mutation)
      %Ecto.Changeset{data: %Mutation{}}

  """
  @spec change_mutation(
          mutation :: Mutation.t() | Mutation.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(Mutation.t())
  def change_mutation(%Mutation{} = mutation, attrs \\ %{}),
    do: Mutation.changeset(mutation, attrs)
end
