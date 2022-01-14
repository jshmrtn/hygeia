defmodule HygeiaCldr do
  @moduledoc false

  use Cldr,
    default_locale: "en-CH",
    locales: ["en", "en-CH", "de", "de-CH", "fr", "fr-CH", "it", "it-CH"],
    gettext: HygeiaGettext,
    otp_app: :hygeia,
    providers: [
      Cldr.Number,
      Cldr.List,
      Cldr.Calendar,
      Cldr.DateTime,
      Cldr.Unit,
      Cldr.Language,
      Cldr.Message
    ],
    generate_docs: true,
    force_locale_download: false

  defmodule GettextInterpolation do
    @moduledoc false
    use Cldr.Gettext.Interpolation, cldr_backend: HygeiaCldr
  end
end
