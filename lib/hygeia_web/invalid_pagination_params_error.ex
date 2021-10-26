defmodule HygeiaWeb.InvalidPaginationParamsError do
  @moduledoc false
  defexception plug_status: 400,
               message: "invalid params"

  @impl Exception
  def exception(_opts) do
    %__MODULE__{message: "invalid params"}
  end
end
