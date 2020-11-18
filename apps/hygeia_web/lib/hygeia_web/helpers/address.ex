defmodule HygeiaWeb.Helpers.Address do
  @moduledoc false

  alias Hygeia.CaseContext.Address

  @spec format_address(address :: nil) :: nil
  def format_address(nil), do: nil
  @spec format_address(address :: Address.t()) :: String.t()
  def format_address(address), do: Address.to_string(address, :short)
end
