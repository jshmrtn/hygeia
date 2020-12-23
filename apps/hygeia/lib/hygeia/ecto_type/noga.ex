defmodule Hygeia.EctoType.NOGA do
  @moduledoc """
  Type for NOGA professions
  """

  alias Hygeia.EctoType.NOGA
  alias Hygeia.EctoType.NOGA.Code
  alias Hygeia.EctoType.NOGA.Section

  files =
    __ENV__.file
    |> Path.dirname()
    |> Path.join("noga/*.csv")
    |> Path.wildcard()

  for file <- files do
    @external_resource file
  end

  locales = Enum.map(files, &(&1 |> Path.basename(".csv") |> String.to_atom()))

  sections =
    files
    |> Enum.map(&File.stream!/1)
    |> Enum.map(&CSV.decode!(&1, headers: true))
    |> Enum.zip(locales)
    |> Enum.flat_map(fn {csv, locale} ->
      Enum.map(csv, fn %{"section" => section, "code" => code, "title" => title} = _line ->
        %{
          # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
          section: String.to_atom(section),
          code:
            case code do
              "0" -> nil
              # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
              _other -> String.to_atom(code)
            end,
          title: title,
          locale: locale
        }
      end)
    end)
    |> Enum.group_by(&{&1.section, &1.code}, &{&1.locale, &1.title})
    |> Enum.group_by(
      fn
        {{section, _code}, _translations} -> section
      end,
      fn
        {{_section, code}, translations} ->
          {code, translations}
      end
    )

  enum_options =
    Enum.flat_map(sections, fn {section, codes} ->
      [section | codes |> Keyword.keys() |> Enum.reject(&is_nil/1)]
    end)

  locale_type = Enum.reduce(locales, &{:|, [], [&1, &2]})

  @typedoc "Available Locales"
  @type locale :: unquote(locale_type)

  defmodule Section do
    @moduledoc """
    Type for Section only
    """

    section_enum_options = Map.keys(sections)

    use EctoEnum.Postgres, type: :noga_section, enums: section_enum_options

    @doc "Get Section Title for current locale"
    @spec title(section :: t) :: String.t()
    def title(section),
      do: title(section, HygeiaGettext |> Gettext.get_locale() |> String.to_existing_atom())

    @doc "Get Section Title by locale"
    @spec title(section :: t, locale :: NOGA.locale()) :: String.t()
    for {section, codes} <- sections,
        {locale, translation} <- codes[nil] do
      def title(unquote(section), unquote(locale)), do: unquote(translation)
    end

    @doc "Get Section Title for current locale"
    @spec select_options :: [{String.t(), t()}]
    def select_options,
      do: HygeiaGettext |> Gettext.get_locale() |> String.to_existing_atom() |> select_options()

    @doc "Get Options for Select by locale"
    @spec select_options(locale :: NOGA.locale()) :: [{String.t(), t()}]
    for locale <- locales do
      options =
        Enum.map(sections, fn {section, codes} ->
          {codes[nil][locale], section}
        end)

      def select_options(unquote(locale)), do: unquote(options)
    end
  end

  defmodule Code do
    @moduledoc """
    Type for Code only
    """

    code_enum_options =
      Enum.flat_map(sections, fn {_section, codes} ->
        codes |> Keyword.keys() |> Enum.reject(&is_nil/1)
      end)

    use EctoEnum.Postgres, type: :noga_code, enums: code_enum_options

    @doc "Get Code Section"
    @spec section(code :: t) :: Section.t()
    for {section, codes} <- sections,
        {code, _translations} <- codes,
        not is_nil(code) do
      def section(unquote(code)), do: unquote(section)
    end

    @doc "Get Code Title for current locale"
    @spec title(code :: t) :: String.t()
    def title(code),
      do: title(code, HygeiaGettext |> Gettext.get_locale() |> String.to_existing_atom())

    @doc "Get Code Title by locale"
    @spec title(code :: t, locale :: NOGA.locale()) :: String.t()
    for {_section, codes} <- sections,
        {code, translations} <- codes,
        not is_nil(code),
        {locale, translation} <- translations do
      def title(unquote(code), unquote(locale)), do: unquote(translation)
    end

    @doc "Get Section Title for current locale"
    @spec select_options(section :: Section.t()) :: [{String.t(), t()}]
    def select_options(section),
      do:
        select_options(
          section,
          HygeiaGettext |> Gettext.get_locale() |> String.to_existing_atom()
        )

    @doc "Get Options for Select by locale"
    @spec select_options(section :: Section.t(), locale :: NOGA.locale()) :: [{String.t(), t()}]
    for locale <- locales,
        {section, codes} <- sections do
      options =
        codes
        |> Enum.reject(&match?({nil, _translations}, &1))
        |> Enum.map(fn {code, translations} ->
          level =
            code
            |> Atom.to_string()
            |> String.length()
            |> Kernel.-(2)

          {String.duplicate("- ", level) <> translations[locale], code}
        end)
        |> Enum.sort_by(&elem(&1, 1))

      def select_options(unquote(section), unquote(locale)), do: unquote(options)
    end
  end
end
