defmodule HygeiaCldr do
  @moduledoc false

  use Cldr,
    default_locale: "en-CH",
    locales: ["en", "en-CH", "de", "de-CH", "fr", "fr-CH", "it", "it-CH"],
    gettext: HygeiaGettext,
    otp_app: :hygeia_cldr,
    providers: [Cldr.Number, Cldr.List, Cldr.Calendar, Cldr.DateTime, Cldr.Unit, Cldr.Language],
    generate_docs: true,
    force_locale_download: false
end
