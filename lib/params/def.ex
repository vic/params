defmodule Params.Def do

  defmacro defparams({name, _, [schema = {:%{}, _, _ }]}, [do: block]) do
    {dict, _} = Code.eval_quoted(schema, env: __CALLER__)
    mod_name = module_name(Params, name)
    quote do
      unquote(defschema(normalize_schema(mod_name, dict)))
      unquote(defun(mod_name, name))
      unquote(block)
    end
  end

  defmacro defparams({name, _, [schema = {:%{}, _, _ }]}) do
    {dict, _} = Code.eval_quoted(schema, env: __CALLER__)
    mod_name = module_name(Params, name)
    quote do
      unquote(defschema(normalize_schema(mod_name, dict)))
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

  defp defschema(schema) do
    module_name = Keyword.get(List.first(schema), :module)
    quote do
      defmodule unquote(module_name) do
        use Params.Schema
        @required unquote(field_names(schema, &is_required?/1))
        @optional unquote(field_names(schema, &is_optional?/1))
        schema do
          unquote_splicing(schema_fields(schema))
        end
      end
      unquote_splicing(embed_schemas(schema))
    end
  end

  defp is_required?(field_schema) do
    Keyword.get(field_schema, :required, false)
  end

  defp is_optional?(field_schema) do
    !is_required?(field_schema)
  end

  defp field_names(schema, filter) do
    names = fn x -> Keyword.get(x, :name) |> Atom.to_string end
    schema |> Enum.filter_map(filter, names)
  end

  defp embed_schemas(schemas) do
    embedded? = fn x -> Keyword.has_key?(x, :embeds) end
    gen_schema = fn x -> defschema(Keyword.get(x, :embeds)) end
    schemas |> Enum.filter_map(embedded?, gen_schema)
  end

  defp schema_fields(schema) do
    Enum.map(schema, &schema_field/1)
  end

  defp schema_field(meta) do
    {call, name, type, opts} = {field_call(meta),
                                Keyword.get(meta, :name),
                                field_type(meta),
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

  defp field_type(meta) do
    module = Keyword.get(meta, :module)
    name   = Keyword.get(meta, :name)
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

  defp normalize_field({module, k, v}) do
    required = String.ends_with?("#{k}", "!")
    name = String.replace_trailing("#{k}", "!", "") |> String.to_atom
    normalize_field(v, [name: name, required: required, module: module])
  end

  defp normalize_field(value, options) when is_atom(value) do
    [field: value] ++ options
  end

  defp normalize_field(schema = %{}, options) do
    embedded = module_name Keyword.get(options, :module), Keyword.get(options, :name)
    [embeds: normalize_schema(embedded, schema)] ++ options
  end

  defp normalize_field([x], options) do
    [cardinality: :many] ++ normalize_field(x, options)
  end

end
