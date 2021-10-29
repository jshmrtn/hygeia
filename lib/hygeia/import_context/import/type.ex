defmodule Hygeia.ImportContext.Import.Type do
  @moduledoc """
  Type of Import (Timestamped)
  """

  use EctoEnum, type: :case_import_type, enums: [:ism_2021_06_11_death, :ism_2021_06_11_test]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(type)
  def translate(:ism_2021_06_11_death), do: pgettext("Case Import Type", "ISM (06/11/2021) Death")
  def translate(:ism_2021_06_11_test), do: pgettext("Case Import Type", "ISM (06/11/2021) Test")

  @spec id_fields(type :: t) :: [String.t()]
  def id_fields(type), do: action_plan_generator(type).id_fields()

  @spec display_field_grouping(type :: t) :: %{
          (section_name :: String.t()) => MapSet.t(field_name :: String.t())
        }
  def display_field_grouping(type), do: action_plan_generator(type).display_field_grouping()

  @spec list_fields(type :: t) :: [field_name :: String.t()]
  def list_fields(type), do: action_plan_generator(type).list_fields()

  @spec action_plan_generator(type :: t) :: module
  def action_plan_generator(type)

  def action_plan_generator(:ism_2021_06_11_death),
    do: Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Death

  def action_plan_generator(:ism_2021_06_11_test),
    do: Hygeia.ImportContext.Planner.Generator.ISM_2021_06_11_Test
end
