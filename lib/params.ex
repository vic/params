defmodule Params do
  @moduledoc ~S"""
  Functions for processing params and transforming their changesets.

  `use Params` provides a `defparams` macro, allowing you to define
  functions that process parameters according to some [schema](Params.Schema.html).

  ## Example

      defmodule MyApp.SessionController do
        use Params

        defparams login_params(%{email!: :string, :password!: :string})

        def create(conn, params) do
          case login_params(params) do
            %Ecto.Changeset{valid?: true} = ch ->
              login = Params.data(ch)
              User.authenticate(login.email, login.password)
              # ...
            _ -> text(conn, "Invalid parameters")
          end
        end
      end

  """

  @relations [:embed, :assoc]
  alias Ecto.Changeset

  @doc false
  defmacro __using__([]) do
    quote do
      import Params.Def, only: [defparams: 1, defparams: 2, defschema: 1]
    end
  end

  @doc """
  Transforms an Ecto.Changeset into a Map with atom keys.

  Recursively traverses and transforms embedded changesets and skips keys that
  was not part of params given to changeset
  """
  @spec to_map(Changeset.t()) :: map
  def to_map(%Changeset{data: %{__struct__: module}} = ch) do
    ecto_defaults = module |> plain_defaults_defined_by_ecto_schema
    params_defaults = module |> schema |> defaults
    change = changes(ch)

    ecto_defaults
    |> deep_merge(params_defaults)
    |> deep_merge(change)
  end

  @doc """
  Transforms an Ecto.Changeset into a struct.

  Recursively traverses and transforms embedded changesets.

  For example if the `LoginParams` module was defined like:

  ```elixir
  defmodule LoginParams do
     use Params.Schema, %{login!: :string, password!: :string}
  end
  ```

  You can transform the changeset returned by `from` into an struct like:

  ```elixir
  data = LoginParams.from(%{"login" => "foo"}) |> Params.data
  data.login # => "foo"
  ```
  """
  @spec data(Changeset.t()) :: struct
  def data(%Changeset{data: data = %{__struct__: module}} = ch) do
    default_embeds = default_embeds_from_schema(module)

    default =
      Enum.reduce(default_embeds, data, fn {k, v}, m ->
        Map.put(m, k, Map.get(m, k) || v)
      end)

    Enum.reduce(ch.changes, default, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, data(v))
        x = [%Changeset{} | _] -> Map.put(m, k, Enum.map(x, &data/1))
        _ -> Map.put(m, k, v)
      end
    end)
  end

  @doc false
  def default_embeds_from_schema(module) when is_atom(module) do
    is_embed_default = fn kw ->
      Keyword.get(kw, :embeds, [])
      |> Enum.any?(&Keyword.has_key?(&1, :default))
    end

    default_embed = fn kw ->
      name = Keyword.get(kw, :name)
      embed_name = Params.Def.module_concat(module, name)
      {name, default_embeds_from_schema(embed_name)}
    end

    case schema(module) do
      nil ->
        %{}

      schema ->
        schema
        |> Stream.filter(is_embed_default)
        |> Stream.map(default_embed)
        |> Enum.into(struct(module) |> Map.from_struct())
    end
  end

  @doc false
  def schema(module) when is_atom(module) do
    module.__info__(:attributes) |> Keyword.get(:schema)
  end

  @doc false
  def required(module) when is_atom(module) do
    module.__info__(:attributes) |> Keyword.get(:required, [])
  end

  @doc false
  def optional(module) when is_atom(module) do
    module.__info__(:attributes)
    |> Keyword.get(:optional)
    |> case do
      nil -> module.__changeset__() |> Map.keys()
      x -> x
    end
  end

  @doc false
  def changeset(%Changeset{data: %{__struct__: module}} = changeset, params) do
    {required, required_relations} =
      relation_partition(module, required(module))

    {optional, optional_relations} =
      relation_partition(module, optional(module))

    changeset
    |> Changeset.cast(params, required ++ optional)
    |> Changeset.validate_required(required)
    |> cast_relations(required_relations, required: true)
    |> cast_relations(optional_relations, [])
  end

  @doc false
  def changeset(model = %{__struct__: _}, params) do
    changeset(model |> change, params)
  end

  @doc false
  def changeset(module, params) when is_atom(module) do
    changeset(module |> change, params)
  end

  defp change(%{__struct__: _} = model) do
    model |> Changeset.change()
  end

  defp change(module) when is_atom(module) do
    module |> struct |> Changeset.change()
  end

  defp relation_partition(module, names) do
    types = module.__changeset__()

    names
    |> Stream.map(fn x -> String.to_atom("#{x}") end)
    |> Enum.reduce({[], []}, fn name, {fields, relations} ->
      case Map.get(types, name) do
        {type, _} when type in @relations ->
          {fields, [{name, type} | relations]}

        _ ->
          {[name | fields], relations}
      end
    end)
  end

  defp cast_relations(changeset, relations, opts) do
    Enum.reduce(relations, changeset, fn
      {name, :assoc}, ch -> Changeset.cast_assoc(ch, name, opts)
      {name, :embed}, ch -> Changeset.cast_embed(ch, name, opts)
    end)
  end

  defp deep_merge(%{} = map_1, %{} = map_2) do
    Map.merge(map_1, map_2, &deep_merge_conflict/3)
  end

  defp deep_merge_conflict(_k, %{} = m1, %{} = m2) do
    deep_merge(m1, m2)
  end

  defp deep_merge_conflict(_k, _v1, v2), do: v2

  defp defaults(params), do: defaults(params, %{}, [])
  defp defaults(params, acc, path)
  defp defaults([], acc, _path), do: acc
  defp defaults(nil, _acc, _path), do: %{}

  defp defaults([opts | rest], acc, path) when is_list(opts) do
    defaults([Enum.into(opts, %{}) | rest], acc, path)
  end

  defp defaults([%{name: name, embeds: embeds} | rest], acc, path) do
    acc = defaults(embeds, acc, [name | path])
    defaults(rest, acc, path)
  end

  defp defaults([%{name: name, default: value} | rest], acc, path) do
    funs =
      [name | path]
      |> Enum.reverse()
      |> Enum.map(fn nested_name ->
        fn :get_and_update, data, next ->
          with {nil, inner_data} <- next.(data[nested_name] || %{}),
               data = Map.put(data, nested_name, inner_data),
               do: {nil, data}
        end
      end)

    acc = put_in(acc, funs, value)
    defaults(rest, acc, path)
  end

  defp defaults([%{} | rest], acc, path) do
    defaults(rest, acc, path)
  end

  defp changes(%Changeset{} = ch) do
    Enum.reduce(ch.changes, %{}, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, changes(v))
        x = [%Changeset{} | _] -> Map.put(m, k, Enum.map(x, &changes/1))
        _ -> Map.put(m, k, v)
      end
    end)
  end

  defp plain_defaults_defined_by_ecto_schema(module) do
    module
    |> struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end
end
