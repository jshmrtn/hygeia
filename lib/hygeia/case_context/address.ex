defmodule Hygeia.CaseContext.Address do
  @moduledoc """
  Model for Address Schema
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.EctoType.Country

  @type empty :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: Country.t() | nil
        }

  @type t :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: Country.t() | nil
        }

  @type changeset_options :: %{optional(:required) => boolean}

  embedded_schema do
    field :address, :string
    field :zip, :string
    field :place, :string
    field :subdivision, :string
    field :country, Country, default: "CH"
  end

  @doc false
  @spec changeset(
          address :: t | empty,
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: changeset_options
        ) :: Changeset.t()
  def changeset(address, attrs, opts \\ %{})

  def changeset(nil, _attrs, %{required: true} = _opts) do
    %__MODULE__{}
    |> change()
    |> add_error(:address, dgettext("errors", "is invalid"))
  end

  def changeset(address, attrs, %{required: true} = opts) do
    address
    |> changeset(attrs, %{opts | required: false})
    |> validate_required([:country, :address])
    |> validate_subdivision_required(:subdivision, :country)
  end

  def changeset(address, attrs, _opts) do
    address
    |> cast(attrs, [:address, :zip, :place, :subdivision, :country])
    |> validate_required([])
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

  @spec merge(old :: t() | Ecto.Changeset.t(t()), new :: t() | Ecto.Changeset.t(t())) ::
          Ecto.Changeset.t(t())
  def merge(old, new) do
    merge(old, new, __MODULE__)
  end
end
