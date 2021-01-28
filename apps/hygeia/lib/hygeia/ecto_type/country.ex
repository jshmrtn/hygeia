defmodule Hygeia.EctoType.Country do
  @moduledoc """
  Type for BFS Country
  """

  use Ecto.Type

  alias Hygeia.Country.ECH007210

  require ECH007210

  bfs_code_xml_path =
    __ENV__.file
    |> Path.dirname()
    |> Path.join("country/eCH0072_191023.xml")

  @external_resource bfs_code_xml_path

  @country_ids Cadastre.Country.ids()

  @type t :: <<_::16>>

  @impl Ecto.Type
  def type, do: :text

  @impl Ecto.Type
  def cast(country) when country in @country_ids, do: {:ok, country}
  def cast(_other), do: :error

  @impl Ecto.Type
  def load(country) when country in @country_ids, do: {:ok, country}
  def load(_other), do: :error

  @impl Ecto.Type
  def dump(country) when country in @country_ids, do: {:ok, country}
  def dump(_other), do: :error

  {:ok, root_node, _rest} =
    bfs_code_xml_path
    |> File.read!()
    |> ECH007210.read()

  bfs_code_lookup =
    root_node
    |> ECH007210.countries()
    |> Keyword.fetch!(:country)
    |> Enum.reduce(%{}, fn
      ECH007210.countryType(iso2Id: :undefined), acc ->
        acc

      ECH007210.countryType(id: :undefined), acc ->
        acc

      ECH007210.countryType(iso2Id: iso2, id: bfs_id), acc ->
        Map.put_new(acc, List.to_string(iso2), bfs_id |> List.to_string() |> String.to_integer())
    end)

  @spec bfs_code(country :: t) :: pos_integer()
  def bfs_code(country)

  for iso2 <- @country_ids do
    def bfs_code(unquote(iso2)), do: unquote(Map.get(bfs_code_lookup, iso2))
  end
end
