defmodule Hygeia.Helpers.Anonymization do
  @moduledoc false

  alias Hygeia.CaseContext.Test
  alias Hygeia.CaseContext.Transmission

  @spec anonymize_transmission_params(transmissions :: [Transmission.t()]) :: [map()]
  def anonymize_transmission_params(transmissions) do
    Enum.map(
      transmissions,
      fn %Transmission{} = transmission ->
        transmission
        |> Map.from_struct()
        |> Map.put(:comment, nil)
        |> Map.update!(
          :infection_place,
          &(&1 |> Map.from_struct() |> Map.merge(%{name: nil, address: nil}))
        )
      end
    )
  end

  @spec anonymize_test_params(tests :: [Test.t()]) :: [map()]
  def anonymize_test_params(tests) do
    Enum.map(
      tests,
      fn %Test{} = test ->
        test
        |> Map.from_struct()
        |> Map.merge(%{tested_at: nil, reporting_unit: nil})
      end
    )
  end
end
