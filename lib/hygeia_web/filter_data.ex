defimpl Phoenix.HTML.FormData, for: Map do
  @spec to_form(Phoenix.HTML.FormData.t(), Keyword.t()) :: Phoenix.HTML.Form.t()
  def to_form(filter_data, options) do
    {name, options} = Keyword.pop(options, :as)

    %Phoenix.HTML.Form{
      source: filter_data,
      impl: Map,
      id: name,
      name: name,
      params: filter_data,
      data: filter_data,
      errors: [],
      options: options
    }
  end

  @spec to_form(
          Phoenix.HTML.FormData.t(),
          Phoenix.HTML.Form.t(),
          Phoenix.HTML.Form.field(),
          Keyword.t()
        ) :: [Phoenix.HTML.Form.t()]
  def to_form(data, form, field, options) do
    {prepend, options} = Keyword.pop(options, :prepend, [])
    {append, options} = Keyword.pop(options, :append, [])
    {name, options} = Keyword.pop(options, :as)
    {id, options} = Keyword.pop(options, :id)

    id = to_string(id || form.id <> "_#{field}")
    name = to_string(name || form.name <> "[#{field}]")

    case data do
      %{^field => values} when is_list(values) ->
        Enum.map(
          prepend ++ values ++ append,
          &%Phoenix.HTML.Form{
            source: &1,
            impl: __MODULE__,
            id: id,
            name: name,
            errors: [],
            data: &1,
            params: &1,
            options: options
          }
        )

      %{^field => value} when is_map(value) ->
        [
          %Phoenix.HTML.Form{
            source: value,
            impl: __MODULE__,
            id: id,
            name: name,
            errors: [],
            data: value,
            params: value,
            options: options
          }
        ]

      %{^field => _value} ->
        raise "data.#{field} is not a list nor a map"
    end
  end

  @spec input_value(Phoenix.HTML.FormData.t(), Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field()) ::
          term()
  def input_value(data, _form, field) do
    case data do
      %{^field => value} -> value
      _missing -> nil
    end
  end

  @spec input_type(Phoenix.HTML.FormData.t(), Phoenix.HTML.Form.t(), Phoenix.HTML.Form.field()) ::
          atom() | nil
  def input_type(_data, _form, _field), do: nil

  @spec input_validations(
          Phoenix.HTML.FormData.t(),
          Phoenix.HTML.Form.t(),
          Phoenix.HTML.Form.field()
        ) :: Keyword.t()
  def input_validations(_data, _form, _field), do: []
end
