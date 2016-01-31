defmodule Params do
  @moduledoc ~S"""
  Functions for processing params and transforming their changesets.

  `use Params` provides a `defparams` macro, allowing you to define
  functions that process parameters according to some [schema](Params.Schema.html)

  ## Example

  ```elixir
    defmodule MyApp.SessionController do
      use Params

      defparams login_params(%{email!: :string, :password!: :string})

      def create(conn, params) do
        case login_params(params) do
          %Ecto.Changeset{valid?: true} = ch ->
            login = Params.model(ch)
            User.authenticate(login.email, login.password)
            # ...
          _ -> text(conn, "Invalid parameters")
        end
      end
    end
  ```

  """

  @relations [:embed, :assoc]
  alias Ecto.Changeset

  @doc false
  defmacro __using__([]) do
    quote do
      import Params.Def, only: [defparams: 1, defparams: 2]
    end
  end

  @doc """
  Transforms an Ecto.Changeset into a Map with atom keys.

  Recursively traverses and transforms embedded changesets.
  """
  @spec changes(Changeset.t) :: map
  def changes(%Changeset{} = ch) do
    Enum.reduce(ch.changes, %{}, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, changes(v))
        x = [%Changeset{} | _] -> Map.put(m, k, Enum.map(x, &changes/1))
        _ -> Map.put(m, k, v)
      end
    end)
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
  model = LoginParams.from(%{"login" => "foo"}) |> Params.model
  model.login # => "foo"
  ```
  """
  @spec model(Changeset.t) :: Struct.t
  def model(%Changeset{model: model} = ch) do
    Enum.reduce(ch.changes, model, fn {k, v}, m ->
      case v do
        %Changeset{} -> Map.put(m, k, model(v))
        x = [%Changeset{} | _] -> Map.put(m, k, Enum.map(x, &model/1))
        _ -> Map.put(m, k, v)
      end
    end)
  end

  @doc false
  def required(module) when is_atom(module) do
    module.__info__(:attributes)
    |> Keyword.get(:required, ~w())
  end

  @doc false
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

  @doc false
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

  @doc false
  def changeset(model = %{__struct__: _}, params, changeset_name) do
    changeset(model |> change, params, changeset_name)
  end

  @doc false
  def changeset(module, params, changeset_name)
  when is_atom(module) and is_atom(changeset_name) do
    changeset(module |> change, params, changeset_name)
  end

  defp change(%{__struct__: _} = model) do
    model |> Changeset.change
  end

  defp change(module) when is_atom(module) do
    struct(module) |> Changeset.change
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
