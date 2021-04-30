defmodule Hygeia.ImportContext.Utility do
  @moduledoc false

  alias Hygeia.ImportContext.Import

  defmodule InvalidValueError do
    defexception plug_status: 400,
                 message: "invalid value",
                 value: nil

    @impl Exception
    def exception(opts) do
      value = Keyword.fetch!(opts, :value)

      %__MODULE__{
        message: "an invalid value was provided in the import: #{inspect(value, pretty: true)}",
        value: value
      }
    end
  end

  @spec add_headers(columns :: [column], acc :: acc) ::
          {[%{header => column}], acc :: acc}
        when acc: false | [header], header: String.t(), column: term

  def add_headers(row, false) do
    {[], row}
  end

  def add_headers(row, headers) do
    # Row is reversed so that the first occurance of a field is taken into the map
    # and not the last since the ISM exports contain the same column multiple times

    {[Map.new(Enum.reverse(Enum.zip(headers, row)))], headers}
  end

  @spec extract_row_identifier(type :: Import.Type.t(), row :: map) :: map
  def extract_row_identifier(type, row), do: Map.take(row, Import.Type.id_fields(type))

  @spec normalize_values!(row :: map) :: map
  def normalize_values!(row), do: Map.new(row, &{elem(&1, 0), normalize_value!(elem(&1, 1))})

  defp normalize_value!(value)
  defp normalize_value!(value) when is_binary(value), do: value
  defp normalize_value!(nil), do: nil
  defp normalize_value!(value) when is_integer(value), do: value
  defp normalize_value!(value) when is_float(value), do: value

  defp normalize_value!({year, month, day}) do
    case Date.new(year, month, day) do
      {:ok, date} -> date
      {:error, _reason} -> raise InvalidValueError, value: {year, month, day}
    end
  end

  defp normalize_value!(%NaiveDateTime{} = value), do: value

  defp normalize_value!(value), do: raise(InvalidValueError, value: value)
end
