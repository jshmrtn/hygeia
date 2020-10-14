defmodule HygeiaWeb.Cldr do
  @moduledoc false

  use Cldr,
    default_locale: "en-CH",
    locales: ["en-CH", "de-CH", "fr-CH", "it-CH"],
    gettext: HygeiaWeb.Gettext,
    data_dir: "./priv/cldr",
    otp_app: :hygeia_web,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Cldr.Unit, Cldr.Language],
    generate_docs: true,
    force_locale_download: false
end
