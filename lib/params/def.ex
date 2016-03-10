defmodule Params.Def do

  @moduledoc false

  @doc false
  defmacro defparams({name, _, [schema]}, [do: block]) do
    block = Macro.escape(block)
    quote bind_quoted: [name: name, schema: schema, block: block] do
      Module.eval_quoted(__MODULE__, Params.Def.define(schema, name, block))
    end
  end

  @doc false
  defmacro defparams({name, _, [schema]}) do
    quote bind_quoted: [name: name, schema: schema] do
      Module.eval_quoted(__MODULE__, Params.Def.define(schema, name, nil))
    end
  end

  @doc false
  def defschema(schema) do
    quote bind_quoted: [schema: schema] do
      Module.eval_quoted(__MODULE__, Params.Def.define(schema, __MODULE__))
    end
  end

  @doc false
  def define(schema, module) do
    schema |> normalize_schema(module) |> gen_schema
  end

  @doc false
  def define(schema, name, block) do
    module = module_concat(Params, name)
    [gen_schema(module, normalize_schema(schema, module), block), gen_from(module, name)]
  end

  defp gen_from(module, name) do
    quote do
      def unquote(name)(params, options \\ []) do
        unquote(module).from(params, options)
      end
    end
  end

  defp module_concat(parent, name) do
    Module.concat [parent, Macro.camelize("#{name}")]
  end

  defp gen_schema(schema) do
    quote do
      unquote_splicing(embed_schemas(schema))
      use Params.Schema
      @required unquote(field_names(schema, &is_required?/1))
      @optional unquote(field_names(schema, &is_optional?/1))
      schema do
        unquote_splicing(schema_fields(schema))
      end
    end
  end

  defp gen_schema(:embeds, schema) do
    module = schema |> List.first |> Keyword.get(:module)
    gen_schema(module, schema, nil)
  end

  defp gen_schema(module, schema, block) do
    quote do
      defmodule unquote(module) do
        unquote(gen_schema(schema))
        unquote(block)
      end
    end
  end

  defp is_required?(field_schema) do
    Keyword.get(field_schema, :required, false)
  end

  defp is_optional?(field_schema) do
    !is_required?(field_schema)
  end

  defp field_names(schema, filter) do
    schema |> Enum.filter_map(filter, &Keyword.get(&1, :name))
  end

  defp embed_schemas(schemas) do
    embedded? = fn x -> Keyword.has_key?(x, :embeds) end
    gen = fn x -> gen_schema(:embeds, Keyword.get(x, :embeds)) end
    schemas |> Enum.filter_map(embedded?, gen)
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
      Keyword.get(meta, :embeds) -> module_concat(module, name)
    end
  end

  defp field_options(meta) do
    Keyword.drop(meta, [:module, :name, :field, :embeds, :required, :cardinality])
  end

  defp normalize_schema(dict, module) do
    Enum.reduce(dict, [], fn {k,v}, list ->
      [normalize_field({module, k, v}) | list]
    end)
  end

  defp normalize_field({module, k, v}) do
    required = String.ends_with?("#{k}", "!")
    name = String.replace_trailing("#{k}", "!", "") |> String.to_atom
    normalize_field(v, [name: name, required: required, module: module])
  end

  defp normalize_field(schema = %{}, options) do
    module = module_concat Keyword.get(options, :module), Keyword.get(options, :name)
    [embeds: normalize_schema(schema, module)] ++ options
  end

  defp normalize_field(value, options) when is_atom(value) do
    [field: value] ++ options
  end

  defp normalize_field({:array, x}, options) do
    normalize_field([x], options)
  end

  defp normalize_field([x], options) when is_map(x) do
    [cardinality: :many] ++ normalize_field(x, options)
  end

  defp normalize_field([value], options) when is_atom(value) do
    [field: {:array, value}] ++ options
  end

end
