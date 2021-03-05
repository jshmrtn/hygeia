defmodule HygeiaWeb.Helpers.Versioning do
  @moduledoc false

  import HygeiaGettext

  {:ok, hygeia_modules} = :application.get_key(:hygeia, :modules)

  @item_table_module_mapping Enum.reject(
                               for module <- hygeia_modules, into: %{} do
                                 try do
                                   {module, module.__schema__(:source)}
                                 rescue
                                   UndefinedFunctionError -> {module, nil}
                                 end
                               end,
                               &match?({_module, nil}, &1)
                             )

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
