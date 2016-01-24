defmodule Params.Def do

  defmacro defparams({name, _, [schema = {:%{}, _, _ }]}) do
    {dict, _} = Code.eval_quoted(schema, env: __CALLER__)
    mod_name = module_name(Params, name)
    quote do
      unquote(defschema(mod_name, normalize_schema(mod_name, dict)))
      unquote(defun(mod_name, name))
    end
  end

  defp defun(module, name) do
    quote do
      def unquote(name)(params) do
        unquote(module).from(params)
      end
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
    Enum.map(schema, fn meta -> schema_field(module, meta) end)
  end

  defp schema_field(module, meta) do
    {call, name, type, opts} = {field_call(meta),
                                Keyword.get(meta, :name),
                                field_type(module, meta),
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

  defp field_type(module, meta) do
    name = Keyword.get(meta, :name)
    cond do
      Keyword.get(meta, :field) -> Keyword.get(meta, :field)
      Keyword.get(meta, :embeds) -> module_name(module, name)
    end
  end

  defp field_options(meta) do
    Keyword.drop(meta, [:module, :name, :field, :embeds, :required])
  end

  defp normalize_schema(module, dict) do
    Enum.reduce(dict, [], fn {k,v}, list ->
      [normalize_field({module, k, v}) | list]
    end)
  end

  defp normalize_field({module, k, v}) when is_list(v) do
    [module: module, name: k] ++ v
  end

  defp normalize_field({module, k, v}) do
    required = String.ends_with?("#{k}", "!")
    name = String.replace_trailing("#{k}", "!", "") |> String.to_atom
    normalize_field(v, [name: name, required: required, module: module])
  end

  defp normalize_field(value, options) when is_atom(value) do
    [field: value] ++ options
  end

  defp normalize_field(schema = %{}, options) do
    [embeds: normalize_schema(Keyword.get(options, :module), schema)] ++ options
  end

  defp normalize_field([x], options) do
    [cardinality: :many] ++ normalize_field(x, options)
  end

end
