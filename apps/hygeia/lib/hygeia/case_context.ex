defmodule Hygeia.CaseContext do
  @moduledoc """
  The CaseContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext.Profession

  @doc """
  Returns the list of professions.

  ## Examples

      iex> list_professions()
      [%Profession{}, ...]

  """
  @spec list_professions :: [Profession.t()]
  def list_professions, do: Repo.all(Profession)

  @doc """
  Gets a single profession.

  Raises `Ecto.NoResultsError` if the Profession does not exist.

  ## Examples

      iex> get_profession!(123)
      %Profession{}

      iex> get_profession!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_profession!(id :: String.t()) :: Profession.t()
  def get_profession!(id), do: Repo.get!(Profession, id)

  @doc """
  Creates a profession.

  ## Examples

      iex> create_profession(%{field: value})
      {:ok, %Profession{}}

      iex> create_profession(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_profession(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def create_profession(attrs \\ %{}),
    do:
      %Profession{}
      |> change_profession(attrs)
      |> versioning_insert()
      |> broadcast("professions", :create)
      |> versioning_extract()

  @doc """
  Updates a profession.

  ## Examples

      iex> update_profession(profession, %{field: new_value})
      {:ok, %Profession{}}

      iex> update_profession(profession, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_profession(profession :: Profession.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def update_profession(%Profession{} = profession, attrs),
    do:
      profession
      |> change_profession(attrs)
      |> versioning_update()
      |> broadcast("professions", :update)
      |> versioning_extract()

  @doc """
  Deletes a profession.

  ## Examples

      iex> delete_profession(profession)
      {:ok, %Profession{}}

      iex> delete_profession(profession)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_profession(profession :: Profession.t()) ::
          {:ok, Profession.t()} | {:error, Ecto.Changeset.t()}
  def delete_profession(%Profession{} = profession),
    do:
      profession
      |> change_profession
      |> versioning_delete()
      |> broadcast("professions", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profession changes.

  ## Examples

      iex> change_profession(profession)
      %Ecto.Changeset{data: %Profession{}}

  """

  @spec change_profession(
          tenant :: Profession.t() | Profession.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def change_profession(%Profession{} = profession, attrs \\ %{}),
    do: Profession.changeset(profession, attrs)
end
