defmodule Hygeia.CaseContext.Address do
  @moduledoc """
  Model for Address Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: String.t() | nil
        }

  @type t :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: String.t() | nil
        }

  embedded_schema do
    field :address, :string
    field :zip, :string
    field :place, :string
    field :subdivision, :string
    field :country, :string, default: "CH"
  end

  @doc false
  @spec changeset(address :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:address, :zip, :place, :subdivision, :country])
    |> validate_required([])
    |> validate_country(:country)
    |> validate_subdivision(:subdivision, :country)
  end

  @spec to_string(address :: t, format :: :short | :long) :: String.t()
  def to_string(address, format \\ :short)

  def to_string(address, :short) do
    address
    |> address_parts
    |> Enum.join(", ")
  end

  def to_string(address, :long) do
    address
    |> address_parts
    |> Enum.join("\n")
  end

  defp address_parts(address) do
    locale = HygeiaCldr.get_locale().language

    [
      address.address,
      [address.zip, address.place]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" "),
      case address.subdivision do
        nil ->
          nil

        other ->
          address.country
          |> Cadastre.Subdivision.new(other)
          |> Cadastre.Subdivision.name(locale)
      end,
      case address.country do
        nil -> nil
        other -> other |> Cadastre.Country.new() |> Cadastre.Country.name(locale)
      end
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
  end
end
