defmodule HygeiaGettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import HygeiaGettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :hygeia_gettext

  @fuzzy_languages Application.compile_env(:hygeia_gettext, [__MODULE__, :fuzzy_languages], [])

  @spec is_fuzzy_language?(language :: String.t()) :: boolean
  def is_fuzzy_language?(language), do: language in @fuzzy_languages
end
