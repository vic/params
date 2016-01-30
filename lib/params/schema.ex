defmodule Params.Schema do
  @moduledoc ~S"""
  Defines a params schema for a model.

  A params schema is just a map where keys are the parameter name
  (ending with a `!` to mark the parameter as required) and the
  value is either a valid Ecto.Type, another map for embedded schemas
  or an array of those.

  ## Example

  ```elixir
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
  ```

  To get an Ecto.Changeset for ProductSearch params use:

  ```elixir
     changeset = ProductSearch.from(params)
  ```

  To transform the changeset into a map or `%ProductSearch{}`struct use
  [Params.changes/1](Params.html#changes/1) or [Params.model/1](Params.html#model/1)
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
    Params.Def.defschema(schema)
  end

  @doc false
  defmacro schema([do: definition]) do
    quote do
      Ecto.Schema.schema "params #{__MODULE__}" do
        unquote(definition)
      end
    end
  end

  defp __use__(:ecto) do
    quote do
      require Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: false}
      @timestamps_opts []
      @foreign_key_type :binary_id
      @before_compile Ecto.Schema

      Module.register_attribute(__MODULE__, :ecto_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :ecto_assocs, accumulate: true)
      Module.register_attribute(__MODULE__, :ecto_embeds, accumulate: true)
      Module.register_attribute(__MODULE__, :ecto_raw, accumulate: true)
      Module.register_attribute(__MODULE__, :ecto_autogenerate_insert, accumulate: true)
      Module.register_attribute(__MODULE__, :ecto_autogenerate_update, accumulate: true)
      Module.put_attribute(__MODULE__, :ecto_autogenerate_id, nil)
    end
  end

  defp __use__(:params) do
    quote do
      Module.register_attribute(__MODULE__, :required, persist: true)
      Module.register_attribute(__MODULE__, :optional, persist: true)

      @behaviour Params.Behaviour

      def from(params, changeset_name \\ :changeset) do
        ch = %{__struct__: __MODULE__} |> Ecto.Changeset.change
        apply(__MODULE__, changeset_name, [ch, params])
      end

      def model(params, changeset_name \\ :changeset) do
        case from(params, changeset_name) do
          ch = %{valid?: true} -> {:ok, Params.model(ch)}
          ch -> {:error, ch}
        end
      end

      def changeset(changeset, params) do
        Params.changeset(changeset, params, :changeset)
      end

      defoverridable [changeset: 2]
    end
  end

end
