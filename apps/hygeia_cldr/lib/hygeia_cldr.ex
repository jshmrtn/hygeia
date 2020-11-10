defmodule HygeiaCldr do
  @moduledoc false

  use Cldr,
    default_locale: "en-CH",
    locales: ["en-CH", "de-CH", "fr-CH", "it-CH"],
    gettext: HygeiaGettext,
    data_dir: "./priv/cldr",
    otp_app: :hygeia_cldr,
    providers: [Cldr.Number, Cldr.List, Cldr.Calendar, Cldr.DateTime, Cldr.Unit, Cldr.Language],
    generate_docs: true,
    force_locale_download: false
end
