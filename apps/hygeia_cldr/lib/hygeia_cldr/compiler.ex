# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule HygeiaCldr.Compiler do
  @moduledoc false

  # TODO: Remove when the following Issue is resolved:
  # - https://github.com/elixir-cldr/cldr/issues/157

  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable __cldr__: 1

      def __cldr__(:backend), do: super(:backend)
      def __cldr__(:gettext), do: super(:gettext)
      def __cldr__(:data_dir), do: Application.app_dir(super(:otp_app), "priv/cldr")
      def __cldr__(:otp_app), do: super(:otp_app)
      def __cldr__(:config), do: %{super(:config) | data_dir: __cldr__(:data_dir)}
    end
  end
end
