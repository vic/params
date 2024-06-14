defmodule Params.Schema do
  @moduledoc ~S"""
  Defines a params schema for a module.

  A params schema is just a map where keys are the parameter name
  (ending with a `!` to mark the parameter as required) and the
  value is either a valid Ecto.Type, another map for embedded schemas
  or an array of those.

  ## Example

      defmodule ProductSearch do
        use Params.Schema, %{
          text!: :string,
          near: %{
            latitude!:  :float,
            longitude!: :float
          },
          tags: [:string]
        }
      end

  To get an Ecto.Changeset for ProductSearch params use:

      changeset = ProductSearch.from(params)

  To transform the changeset into a map or `%ProductSearch{}`struct use
  [Params.changes/1](Params.html#changes/1) or [Params.data/1](Params.html#data/1)
  respectively.
  """

  @doc false
  defmacro __using__([]) do
    quote do
      import Params.Schema, only: [schema: 1]
      unquote(__use__(:ecto))
      unquote(__use__(:params))
    end
  end

  @doc false
  defmacro __using__(schema) do
    quote bind_quoted: [schema: schema] do
      import Params.Def, only: [defschema: 1]
      Params.Def.defschema(schema)
    end
  end

  @doc false
  defmacro schema(do: definition) do
    quote do
      Ecto.Schema.schema "params #{__MODULE__}" do
        unquote(definition)
      end
    end
  end

  defp __use__(:ecto) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:_id, :binary_id, autogenerate: false}
    end
  end

  defp __use__(:params) do
    quote do
      Module.register_attribute(__MODULE__, :required, persist: true)
      Module.register_attribute(__MODULE__, :optional, persist: true)
      Module.register_attribute(__MODULE__, :schema, persist: true)

      @behaviour Params.Behaviour

      def from(params, options \\ []) when is_list(options) do
        on_cast = Keyword.get(options, :with, &__MODULE__.changeset(&1, &2))
        __MODULE__ |> struct |> Ecto.Changeset.change() |> on_cast.(params)
      end

      def data(params, options \\ []) when is_list(options) do
        case from(params, options) do
          ch = %{valid?: true} -> {:ok, Params.data(ch)}
          ch -> {:error, ch}
        end
      end

      def changeset(changeset, params) do
        Params.changeset(changeset, params)
      end

      defoverridable changeset: 2
    end
  end
end
