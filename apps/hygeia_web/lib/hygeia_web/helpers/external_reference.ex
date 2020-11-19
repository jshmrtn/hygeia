defmodule HygeiaWeb.Helpers.ExternalReference do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.ExternalReference

  @spec external_reference_options :: [{String.t(), ExternalReference.Type.t()}]
  def external_reference_options,
    do:
      Enum.map(
        ExternalReference.Type.__enum_map__(),
        &{translate_external_referecne_type(&1), &1}
      )

  @spec translate_external_referecne_type(type :: ExternalReference.Type.t()) :: String.t()
  def translate_external_referecne_type(:ism_case), do: gettext("ISM")
  def translate_external_referecne_type(:ism_report), do: gettext("ISM Report")
  def translate_external_referecne_type(:other), do: gettext("Other")
end
