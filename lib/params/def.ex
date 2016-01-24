defmodule Params.Def do

  defmacro defparams({name, _, [schema = {:%{}, _, _ }]}) do
    {dict, _} = Code.eval_quoted(schema, env: __CALLER__)
    quote do
      unquote(defschema(module_name(Params, name), normalize_schema(dict)))
    end
  end

  defp module_name(parent, name) do
    "#{parent}." <> Macro.camelize("#{name}") |> String.to_atom
  end

  defp defschema(name, schema) do
    quote do
      defmodule unquote(name) do
        use Params.Schema
        schema do
          unquote_splicing(schema_fields(name, schema))
        end
      end
    end
  end

  defp schema_fields(module, schema) do
    Enum.map(schema, fn {name, meta} -> schema_field(module, name, meta) end)
  end

  defp schema_field(module, name, meta) do
    {call, type, opts} = {field_call(meta),
                          field_type(module, name, meta),
                          field_options(meta)}
    quote do
      unquote(call)(unquote(name), unquote(type), unquote(opts))
    end
  end

  defp field_call(meta) do
    cond do
      Keyword.get(meta, :field) -> :field
      Keyword.get(meta, :embeds) ->
        "embeds_#{Keyword.get(meta, :cardinality, :one)}" |> String.to_atom
    end
  end

  defp field_type(module, name, meta) do
    cond do
      Keyword.get(meta, :field) -> Keyword.get(meta, :field)
      Keyword.get(meta, :embeds) -> module_name(module, name)
    end
  end

  defp field_options(meta) do
    Keyword.drop(meta, [:field, :embeds, :required])
  end

  defp normalize_schema(dict) do
    Enum.reduce(dict, %{}, fn {k,v}, map ->
      required = String.ends_with?("#{k}", "!")
      name = String.replace_trailing("#{k}", "!", "") |> String.to_atom
      Map.put(map, name, normalize_field(v, [required: required]))
    end)
  end

  defp normalize_field(value, options) when is_atom(value) do
    [field: value] ++ options
  end

  defp normalize_field(schema = %{}, options) do
    [embeds: normalize_schema(schema)] ++ options
  end

  defp normalize_field([x], options) do
    [cardinality: :many] ++ normalize_field(x, options)
  end

end
