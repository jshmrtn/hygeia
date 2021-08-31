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

  @doc "Same as dgettext/3 but using ICU Message format"
  defmacro idgettext(domain, msgid, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).dgettext(unquote(domain), unquote(msgid)),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as dngettext/4 but using ICU Message format"
  defmacro idngettext(domain, msgid, msgid_plural, n, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).dngettext(
          unquote(domain),
          unquote(msgid),
          unquote(msgid_plural),
          unquote(n)
        ),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as dpgettext/4 but using ICU Message format"
  defmacro idpgettext(domain, msgctxt, msgid, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).dpgettext(unquote(domain), unquote(msgctxt), unquote(msgid)),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as dpngettext/6 but using ICU Message format"
  defmacro idpngettext(domain, msgctxt, msgid, msgid_plural, n, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).dpngettext(
          unquote(domain),
          unquote(msgctxt),
          unquote(msgid),
          unquote(msgid_plural),
          unquote(n)
        ),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as gettext/2 but using ICU Message format"
  defmacro igettext(msgid, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(unquote(__MODULE__).gettext(unquote(msgid)), unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as lgettext/5 but using ICU Message format"
  @spec ilgettext(
          locale :: Gettext.locale(),
          domain :: String.t(),
          msgctxt :: String.t(),
          msgid :: String.t(),
          bindings :: Gettext.bindings()
        ) :: String.t()
  def ilgettext(locale, domain, msgctxt \\ nil, msgid, bindings) do
    Cldr.Message.format!(lgettext(locale, domain, msgctxt, msgid, %{}), bindings,
      backend: HygeiaCldr
    )
  end

  @doc "Same as lngettext/7 but using ICU Message format"
  @spec ilngettext(
          locale :: Gettext.locale(),
          domain :: String.t(),
          msgctxt :: String.t(),
          msgid :: String.t(),
          msgid_plural :: String.t(),
          n :: non_neg_integer(),
          bindings :: Gettext.bindings()
        ) :: String.t()
  def ilngettext(locale, domain, msgctxt, msgid, msgid_plural, n, bindings) do
    Cldr.Message.format!(
      lngettext(locale, domain, msgctxt, msgid, msgid_plural, n, %{}),
      bindings,
      backend: HygeiaCldr
    )
  end

  @doc "Same as ngettext/4 but using ICU Message format"
  defmacro ingettext(msgid, msgid_plural, n, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).ngettext(unquote(msgid), unquote(msgid_plural), unquote(n)),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as pgettext/3 but using ICU Message format"
  defmacro ipgettext(msgctxt, msgid, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).pgettext(unquote(msgctxt), unquote(msgid)),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end

  @doc "Same as pngettext/5 but using ICU Message format"
  defmacro ipngettext(msgctxt, msgid, msgid_plural, n, bindings \\ Macro.escape(%{})) do
    quote location: :keep, generated: true do
      Cldr.Message.format!(
        unquote(__MODULE__).pngettext(
          unquote(msgctxt),
          unquote(msgid),
          unquote(msgid_plural),
          unquote(n)
        ),
        unquote(bindings),
        backend: HygeiaCldr
      )
    end
  end
end
