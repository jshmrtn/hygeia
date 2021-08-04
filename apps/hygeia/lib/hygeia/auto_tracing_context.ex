defmodule Hygeia.AutoTracingContext do
  @moduledoc """
  The AutoTracingContext context.
  """

  use Hygeia, :context

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext.Case

  @doc """
  Returns the list of auto_tracings.

  ## Examples

      iex> list_auto_tracings()
      [%AutoTracing{}, ...]

  """
  @spec list_auto_tracings :: [AutoTracing.t()]
  def list_auto_tracings, do: Repo.all(AutoTracing)

  @doc """
  Gets a single auto_tracing.

  Raises `Ecto.NoResultsError` if the AutoTracing does not exist.

  ## Examples

      iex> get_auto_tracing!(123)
      %AutoTracing{}

      iex> get_auto_tracing!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_auto_tracing!(id :: Ecto.UUID.t()) :: AutoTracing.t()
  def get_auto_tracing!(id), do: Repo.get!(AutoTracing, id)

  @spec get_auto_tracing_by_case(case :: Case.t()) :: AutoTracing.t() | nil
  def get_auto_tracing_by_case(%Case{} = case), do: Repo.get_by(AutoTracing, case_uuid: case.uuid)

  @doc """
  Creates a auto_tracing.

  ## Examples

      iex> create_auto_tracing(case, %{field: value})
      {:ok, %AutoTracing{}}

      iex> create_auto_tracing(case, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_auto_tracing(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, AutoTracing.t()} | {:error, Ecto.Changeset.t(AutoTracing.t())}
  def create_auto_tracing(case, attrs \\ %{}),
    do:
      %AutoTracing{}
      |> struct()
      |> change_auto_tracing(Enum.into(%{case_uuid: case.uuid}, attrs))
      |> versioning_insert()
      |> broadcast("auto_tracings", :create)
      |> versioning_extract()

  @doc """
  Updates a auto_tracing.

  ## Examples

      iex> update_auto_tracing(auto_tracing, %{field: new_value})
      {:ok, %AutoTracing{}}

      iex> update_auto_tracing(auto_tracing, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_auto_tracing(
          auto_tracing :: AutoTracing.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, AutoTracing.t()} | {:error, Ecto.Changeset.t(AutoTracing.t())}
  def update_auto_tracing(%AutoTracing{} = auto_tracing, attrs),
    do:
      auto_tracing
      |> change_auto_tracing(attrs)
      |> versioning_update()
      |> broadcast("auto_tracings", :update)
      |> versioning_extract()

  @doc """
  Deletes a auto_tracing.

  ## Examples

      iex> delete_auto_tracing(auto_tracing)
      {:ok, %AutoTracing{}}

      iex> delete_auto_tracing(auto_tracing)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_auto_tracing(auto_tracing :: AutoTracing.t()) ::
          {:ok, AutoTracing.t()} | {:error, Ecto.Changeset.t(AutoTracing.t())}
  def delete_auto_tracing(%AutoTracing{} = auto_tracing),
    do:
      auto_tracing
      |> change_auto_tracing()
      |> versioning_delete()
      |> broadcast("auto_tracings", :delete)
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking auto_tracing changes.

  ## Examples

      iex> change_auto_tracing(auto_tracing)
      %Ecto.Changeset{data: %AutoTracing{}}

  """
  @spec change_auto_tracing(
          auto_tracing :: AutoTracing.t() | AutoTracing.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(AutoTracing.t())
  def change_auto_tracing(%AutoTracing{} = auto_tracing, attrs \\ %{}),
    do: AutoTracing.changeset(auto_tracing, attrs)
end
