defmodule Params do

  @relations [:embed, :assoc]
  alias Ecto.Changeset

  defmacro __using__([]) do
    quote do
      import Params.Def, only: [defparams: 1, defparams: 2]
    end
  end

  def changes(%Changeset{} = ch) do
    Enum.reduce(ch.changes, %{}, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, changes(v))
        _ -> Map.put(m, k, v)
      end
    end)
  end

  def model(%Changeset{model: model} = ch) do
    Enum.reduce(ch.changes, model, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, model(v))
        _ -> Map.put(m, k, v)
      end
    end)
  end

  def required(module) when is_atom(module) do
    module.__info__(:attributes)
    |> Keyword.get(:required, ~w())
  end

  def optional(module) when is_atom(module) do
    module.__info__(:attributes)
    |> Keyword.get(:optional)
    |> case do
      nil ->
        module.__changeset__ |> Map.keys
        |> Enum.map(&Atom.to_string/1)
      x -> x
    end
  end

  def changeset(%Changeset{model: %{__struct__: module}} = changeset, params, changeset_name)
  when is_atom(module) and is_atom(changeset_name) do
    {required, required_relations} =
      relation_partition(module, required(module))

    {optional, optional_relations} =
      relation_partition(module, optional(module))

    Changeset.cast(changeset, params, required, optional)
    |> cast_relations(required_relations,
                      required: true, with: changeset_name)
    |> cast_relations(optional_relations,
                      with: changeset_name)
  end

  def changeset(model = %{__struct__: _}, params, changeset_name) do
    changeset(model |> change, params, changeset_name)
  end

  def changeset(module, params, changeset_name)
  when is_atom(module) and is_atom(changeset_name) do
    changeset(module |> change, params, changeset_name)
  end

  defp change(%{__struct__: _} = model) do
    model |> Changeset.change
  end

  defp change(module) when is_atom(module) do
    %{__struct__: module} |> Changeset.change
  end

  defp relation_partition(module, names) do
    types = module.__changeset__

    names
    |> Stream.map(fn x -> String.to_atom("#{x}") end)
    |> Enum.reduce({[], []}, fn name, {fields, relations} ->
      case Map.get(types, name) do
        {type, _} when type in @relations ->
          {fields, [{name, type} | relations]}
        _ ->
          {[Atom.to_string(name) | fields], relations}
      end
    end)
  end

  defp cast_relations(changeset, relations, opts) do
    Enum.reduce(relations, changeset, fn
      {name, type}, ch ->
        case type do
          :assoc -> Changeset.cast_assoc(ch, name, opts)
          :embed -> Changeset.cast_embed(ch, name, opts)
        end
    end)
  end

end
