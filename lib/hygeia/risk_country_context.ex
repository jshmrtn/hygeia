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

  @spec get_risk_country_by_ism_code(ism_code :: integer()) :: RiskCountry.t() | nil
  def get_risk_country_by_ism_code(ism_code)
      when is_integer(ism_code),
      do: Repo.get_by(RiskCountry, ism_code: ism_code)

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
  Updates a risk country.

  ## Examples

      iex> update_risk_country(risk_country, %{field: new_value})
      {:ok, %RiskCountry{}}

      iex> update_risk_country(risk_country, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_risk_country(
          risk_country :: RiskCountry.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          {:ok, RiskCountry.t()} | {:error, Ecto.Changeset.t(RiskCountry.t())}
  def update_risk_country(%RiskCountry{} = risk_country, attrs),
    do:
      risk_country
      |> change_risk_country(attrs)
      |> versioning_update()
      |> broadcast("risk_countries", :update)
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
