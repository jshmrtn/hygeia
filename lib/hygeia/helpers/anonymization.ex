defmodule Hygeia.Helpers.Anonymization do
  @moduledoc false

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case.Monitoring
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
        |> Hygeia.Helpers.Map.from_nested_struct([{DateTime, :skip}])
        |> Map.put(:tested_at, nil)
        |> Map.put(:reporting_unit, anonymize_entity(test.reporting_unit))
        |> Map.put(:sponsor, anonymize_entity(test.sponsor))
      end
    )
  end

  defp anonymize_entity(nil), do: nil

  defp anonymize_entity(entity),
    do:
      entity
      |> Map.from_struct()
      |> Map.merge(%{name: nil, division: nil, person_first_name: nil, person_last_name: nil})
      |> Map.put(:address, anonymize_address_params(entity.address))

  @spec anonymize_address_params(address :: Address.t()) :: map() | nil
  def anonymize_address_params(nil), do: nil

  def anonymize_address_params(%Address{} = address) do
    %{Map.from_struct(address) | address: nil, place: nil, zip: nil}
  end

  @spec anonymize_monitoring_params(monitoring :: Monitoring.t()) :: map() | nil
  def anonymize_monitoring_params(nil), do: nil

  def anonymize_monitoring_params(monitoring),
    do:
      monitoring
      |> Map.from_struct()
      |> Map.put(:location_details, nil)
      |> Map.put(:address, anonymize_address_params(monitoring.address))
end
