defmodule HygeiaWeb.Helpers.Versioning do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.Helpers.Versioning

  @spec translate_versioning_origin(origin :: Versioning.origin()) :: String.t()
  def translate_versioning_origin(:web), do: gettext("Website")

  def translate_versioning_origin(:case_close_email_job),
    do: gettext("Automated Case Close Email")

  def translate_versioning_origin(:user_sync_job), do: gettext("User Sync")
  def translate_versioning_origin(:api), do: gettext("API")
  def translate_versioning_origin(:email_sender), do: gettext("Email Sender")
  def translate_versioning_origin(:sms_Sender), do: gettext("SMS Sender")

  @spec translate_versioning_origin(origin :: String.t()) :: String.t()
  def translate_versioning_origin(origin),
    do: origin |> String.to_existing_atom() |> translate_versioning_origin()

  @item_type_module_mapping %{
    Hygeia.CaseContext.Case => "Case",
    Hygeia.CaseContext.Note => "Note",
    Hygeia.CaseContext.Person => "Person",
    Hygeia.CaseContext.Transmission => "Transmission",
    Hygeia.CommunicationContext.Email => "Email",
    Hygeia.CommunicationContext.SMS => "SMS",
    Hygeia.UserContext.User => "User",
    Hygeia.TenantContext.Tenant => "Tenant",
    Hygeia.OrganisationContext.Organisation => "Organisation"
  }

  @spec item_type_to_module(item_type :: String.t()) :: module
  for {module, item_type} <- @item_type_module_mapping do
    def item_type_to_module(unquote(item_type)), do: unquote(module)
  end

  @spec module_to_item_type(module :: module) :: String.t()
  for {module, item_type} <- @item_type_module_mapping do
    def module_to_item_type(unquote(module)), do: unquote(item_type)
  end

  @spec item_type_translation(item_type :: String.t()) :: String.t()
  for {_module, item_type} <- @item_type_module_mapping do
    def item_type_translation(unquote(item_type)), do: pgettext("Item Type", unquote(item_type))
  end

  @spec module_translation(module :: module) :: String.t()
  for {module, item_type} <- @item_type_module_mapping do
    def module_translation(unquote(module)), do: pgettext("Item Type", unquote(item_type))
  end
end
