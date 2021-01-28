defmodule Sedex.Schema do
  @moduledoc false

  schema_paths =
    :sedex
    |> Application.app_dir("priv/schema/")
    |> Kernel.<>("/*.xsd")
    |> Path.wildcard()

  for path <- schema_paths do
    @external_resource path

    name =
      path
      |> Path.basename(".xsd")
      |> String.replace("-", "_")
      |> Macro.camelize()
      |> String.to_atom()

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    defmodule Module.concat(__MODULE__, name) do
      @moduledoc """
      #{name} schema
      """

      use HygeiaXml, path: path
    end
  end
end
