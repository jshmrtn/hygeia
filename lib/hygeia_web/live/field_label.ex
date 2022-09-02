defmodule HygeiaWeb.FieldLabel do
  @moduledoc false

  use Surface.Component

  import HygeiaWeb.Helpers.FieldName
  import Surface.Components.Form.Utils

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  @doc "The form identifier"
  prop form, :form, from_context: {Form, :form}

  @doc "The field name"
  prop field, :atom, from_context: {Field, :field}

  @doc "The CSS class for the underlying tag"
  prop class, :css_class

  @doc "Options list"
  prop opts, :keyword, default: []

  @doc "Override Schema"
  prop schema, :atom

  @doc """
  The text for the label
  """
  slot default, arg: %{name: :string, schema: :atom, field: :atom}

  @impl Surface.Component
  def render(assigns) do
    helper_opts = props_to_opts(assigns, [:schema])

    # The duplication is not refactored nicely since props does not accept the output of a function call directly

    ~F"""
    <Label form={@form} field={@field} class={@class} opts={@opts}>
      <#slot {
        @default,
        schema: get_schema_name(helper_opts, @form),
        field: cut_relation_uuid(@field, get_schema_name(helper_opts, @form)),
        name:
          schema_field_name(
            cut_relation_uuid(@field, get_schema_name(helper_opts, @form)),
            get_schema_name(helper_opts, @form)
          )
      }>
        {schema_field_name(
          cut_relation_uuid(@field, get_schema_name(helper_opts, @form)),
          get_schema_name(helper_opts, @form)
        )}
      </#slot>
    </Label>
    """
  end

  defp get_schema_name(opts, form) do
    opts = Enum.to_list(opts)

    if Keyword.has_key?(opts, :schema) do
      Keyword.fetch!(opts, :schema)
    else
      case form.source do
        %Ecto.Changeset{data: %schema{}} -> schema
      end
    end
  end

  defp cut_relation_uuid(field, schema) when is_binary(field) do
    field
    |> String.to_existing_atom()
    |> cut_relation_uuid(schema)
  rescue
    ArgumentError -> false
  end

  defp cut_relation_uuid(field, schema) when is_atom(field) do
    :associations
    |> schema.__schema__()
    |> Enum.map(&schema.__schema__(:association, &1))
    |> Enum.find_value(field, fn
      %Ecto.Association.BelongsTo{owner_key: ^field, field: relation_name} -> relation_name
      _other -> false
    end)
  end
end
