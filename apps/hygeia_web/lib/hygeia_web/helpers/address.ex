defmodule HygeiaWeb.Helpers.Address do
  @moduledoc false

  @spec format_address(address :: :address) :: :string
  def format_address(address) do
    place = [address.zip, address.place] |> Enum.filter(fn el -> el != "" end) |> Enum.join(" ")

    [
      address.address,
      place,
      address.country
    ]
    |> Enum.filter(fn el -> el != "" end)
    |> Enum.join(", ")
  end
end
