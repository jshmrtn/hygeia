defmodule HygeiaWeb.Helpers.Versioning do
  @moduledoc false

  import HygeiaGettext

  hygeia_modules = [
    Hygeia.AutoTracingContext.AutoTracing,
    Hygeia.CaseContext.Case,
    Hygeia.CaseContext.Hospitalization,
    Hygeia.CaseContext.Note,
    Hygeia.CaseContext.Person,
    Hygeia.CaseContext.PrematureRelease,
    Hygeia.CaseContext.Test,
    Hygeia.CaseContext.Transmission,
    Hygeia.CommunicationContext.Email,
    Hygeia.CommunicationContext.SMS,
    Hygeia.ImportContext.Import,
    Hygeia.ImportContext.Row,
    Hygeia.MutationContext.Mutation,
    Hygeia.NotificationContext.Notification,
    Hygeia.OrganisationContext.Affiliation,
    Hygeia.OrganisationContext.Division,
    Hygeia.OrganisationContext.Organisation,
    Hygeia.OrganisationContext.Position,
    Hygeia.SystemMessageContext.SystemMessage,
    Hygeia.TenantContext.SedexExport,
    Hygeia.TenantContext.Tenant,
    Hygeia.UserContext.Grant,
    Hygeia.UserContext.User
  ]

  @item_table_module_mapping for module <- hygeia_modules,
                                 into: %{},
                                 do: {module, module.__schema__(:source)}

  @spec item_table_to_module(table_table :: String.t()) :: module
  for {module, table_table} <- @item_table_module_mapping do
    def item_table_to_module(unquote(table_table)), do: unquote(module)
  end

  @spec module_to_item_table(module :: module) :: String.t()
  for {module, item_table} <- @item_table_module_mapping do
    def module_to_item_table(unquote(module)), do: unquote(item_table)
  end

  @spec item_table_translation(item_table :: String.t()) :: String.t()
  for {_module, table_table} <- @item_table_module_mapping do
    def item_table_translation(unquote(table_table)),
      do: pgettext("Item Table", unquote(table_table))
  end

  @spec module_translation(module :: module) :: String.t()
  for {module, table_table} <- @item_table_module_mapping do
    def module_translation(unquote(module)), do: pgettext("Item Table", unquote(table_table))
  end
end
