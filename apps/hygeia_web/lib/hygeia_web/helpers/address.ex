defmodule HygeiaWeb.Helpers.Address do
  @moduledoc false

  alias Hygeia.CaseContext.Address

  @spec format_address(address :: nil) :: nil
  def format_address(nil), do: nil
  @spec format_address(address :: Address.t()) :: String.t()
  def format_address(address) do
    locale = HygeiaWeb.Cldr.get_locale().language

    [
      address.address,
      [address.zip, address.place]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" "),
      case address.country do
        nil -> nil
        other -> other |> Cadastre.Country.new() |> Cadastre.Country.name(locale)
      end
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end
end
