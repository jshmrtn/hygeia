defmodule Hygeia.VersionContext.Version.Origin do
  @moduledoc """
  Event Type
  """

  origins_base = [
    :web,
    :api,
    :user_sync_job,
    :case_close_email_job,
    :email_sender,
    :sms_sender,
    :migration,
    :detect_no_reaction_cases_job
  ]

  origins =
    case Mix.env() do
      :test -> [:test | origins_base]
      _other_env -> origins_base
    end

  use EctoEnum, type: :versioning_origin, enums: origins

  import HygeiaGettext

  @spec translate(origin :: t()) :: String.t()
  def translate(:web), do: pgettext("Versioning Origin", "Website")

  def translate(:case_close_email_job),
    do: pgettext("Versioning Origin", "Automated Case Close Email")

  def translate(:user_sync_job), do: pgettext("Versioning Origin", "User Sync")
  def translate(:api), do: pgettext("Versioning Origin", "API")
  def translate(:email_sender), do: pgettext("Versioning Origin", "Email Sender")
  def translate(:sms_sender), do: pgettext("Versioning Origin", "SMS Sender")
  def translate(:migration), do: pgettext("Versioning Origin", "Migration")

  def translate(:detect_no_reaction_cases_job),
    do: pgettext("Versioning Origin", "Detect No Reaction Cases")
end
