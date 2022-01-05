defmodule Hygeia.RiskCountryContext do
  @moduledoc """
  The RiskCountryContext context.
  """

  use Hygeia, :context

  alias Hygeia.RiskCountryContext.RiskCountry

  @doc """
  Returns the list of risk_countries.

  ## Examples

      iex> list_risk_countries()
      [%RiskCountry{}, ...]

  """
  @spec list_risk_countries :: [RiskCountry.t()]
  def list_risk_countries, do: Repo.all(RiskCountry)

  @doc """
  Gets a single risk country.

  Raises `Ecto.NoResultsError` if the RiskCountry does not exist.

  ## Examples

      iex> get_risk_country!(123)
      %RiskCountry{}

      iex> get_risk_country!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_risk_country!(id :: Ecto.UUID.t()) :: RiskCountry.t()
  def get_risk_country!(id), do: Repo.get!(RiskCountry, id)

  @doc """
  Creates a risk country.

  ## Examples

      iex> create_risk_country(%{field: value})
      {:ok, %RiskCountry{}}

      iex> create_risk_country(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_risk_country(attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, RiskCountry.t()} | {:error, Ecto.Changeset.t(RiskCountry.t())}
  def create_risk_country(attrs \\ %{}),
    do:
      %RiskCountry{}
      |> change_risk_country(attrs)
      |> versioning_insert()
      |> broadcast("risk_countries", :create)
      |> versioning_extract()

  @doc """
  Deletes a risk country.

  ## Examples

      iex> delete_risk_country(risk_country)
      {:ok, %RiskCountry{}}

      iex> delete_risk_country(risk_country)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_risk_country(risk_country :: RiskCountry.t()) ::
          {:ok, RiskCountry.t()} | {:error, Ecto.Changeset.t(RiskCountry.t())}
  def delete_risk_country(%RiskCountry{} = risk_country),
    do:
      risk_country
      |> change_risk_country()
      |> versioning_delete()
      |> broadcast("risk_countries", :delete)
      |> versioning_extract()

  @spec patch_risk_countries(risk_countries :: [String.t()] | []) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def patch_risk_countries(risk_countries) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(
      :delete_all,
      from(r in RiskCountry, where: r.country not in ^risk_countries)
    )
    |> Ecto.Multi.insert_all(
      :insert_all,
      RiskCountry,
      Enum.map(risk_countries, &%{country: &1}),
      conflict_target: [:country],
      on_conflict: :nothing
    )
    |> Hygeia.Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking risk country changes.

  ## Examples

      iex> change_risk_country(risk_country)
      %Ecto.Changeset{data: %RiskCountry{}}

  """
  @spec change_risk_country(
          risk_country :: RiskCountry.t() | RiskCountry.empty(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t(RiskCountry.t())
  def change_risk_country(%RiskCountry{} = risk_country, attrs \\ %{}),
    do: RiskCountry.changeset(risk_country, attrs)
end
