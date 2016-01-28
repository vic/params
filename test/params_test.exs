defmodule ParamsTest do
  use ExUnit.Case
  use Params

  alias  Ecto.Changeset
  import Ecto.Changeset

  defmodule PetParams do
    use Params.Schema
    schema do
      field :name
      field :age, :integer
    end
  end

  test "module has schema types" do
    assert %{age: :integer,
             name: :string,
             id: :binary_id} ==
      PetParams.__changeset__
  end

  test "defaults to no required fields" do
    assert [] == Params.required PetParams
  end

  test "defaults to all optional fields" do
    assert ~w(age id name) == Params.optional PetParams
  end

  test "from returns a changeset" do
    ch = PetParams.from(%{})
    assert %Changeset{} = ch
  end

  test "fields are castable" do
    ch = PetParams.from(%{"age" => "2"})
    assert 2 = Changeset.get_change(ch, :age)
  end

  defmodule LocationParams do
    use Params.Schema
    @required ~w(latitude longitude)
    schema do
      field :latitude,  :float
      field :longitude, :float
    end
  end

  defmodule BusParams do
    use Params.Schema
    @required ~w(origin destination)
    schema do
      embeds_one :origin, LocationParams
      embeds_one :destination, LocationParams
    end
  end

  test "invalid changeset on missing params" do
    assert %{valid?: false} = BusParams.from(%{})
  end

  test "only valid if nested required present" do
    params = %{
      "origin" => %{
        "latitude" => 12.2,
        "longitude" => 13.3
      },
      "destination" => %{
        "latitude" => 12.2,
        "longitude" => 13.3
      }
    }

    assert %{valid?: true} = BusParams.from(params)
  end

  test "invalid if nested required missing" do
    params = %{
      "origin" => %{
        "latitude" => 12.2,
      },
      "destination" => %{
        "longitude" => 13.3
      }
    }

    assert %{valid?: false} = BusParams.from(params)
  end


  test "changes gets casted values" do
    params = %{
      "origin" => %{
        "latitude" => "12.2",
      }
    }
    changes = BusParams.changes(params)
    assert %{origin: %{latitude: 12.2}} = changes
  end

  defparams kitten %{
    breed!:  :string,
    age_min: :integer,
    age_max: :integer,
    near_location!: %{
      latitude: :float,
      longitude: :float
    }
  }

  test "kitten module has list of required fields" do
    assert ["near_location", "breed"] = Params.required(Params.Kitten)
  end

  test "kitten module has list of optional fields" do
    assert ["age_min", "age_max"] = Params.optional(Params.Kitten)
  end

  test "kitten method returns changeset" do
    assert %Changeset{} = kitten(%{})
  end

  test "kitten returns valid changeset when all data is ok" do
    params = %{
      "breed" => "Russian Blue",
      "age_min" => "0",
      "age_max" => "4",
      "near_location" => %{
        "latitude" => "87.5",
        "longitude" => "-90.0"
      }
    }
    assert %Changeset{valid?: true} = kitten(params)
  end

  defparams kid(
      %{
        name: :string,
        age: :integer
      }) do

    def custom(ch, params) do
      cast(ch, params, ~w(name), ~w(age))
      |> validate_inclusion(:age, 10..20)
    end

    def changeset(ch, params) do
      cast(ch, params, ~w(name age), ~w())
      |> validate_inclusion(:age, 1..6)
    end
  end

  test "user can populate with custom changeset" do
    assert %{valid?: false} = kid(%{name: "hugo", age: 5}, :custom)
  end

  test "user can override changeset" do
    assert %{valid?: true} = kid(%{name: "hugo", age: 5})
  end

  test "can obtain model from changeset" do
    m = Params.model kid(%{name: "hugo", age: "5"})
    assert "hugo" = m.name
    assert 5 = m.age
  end

  defmodule SearchUser do
    @schema %{
      name: :string,
      near: %{
        latitude:  :float,
        longitude: :float
      }
    }

    use Params.Schema, @schema

    def changeset(ch, params) do
      cast(ch, params, ~w(name), ~w())
      |> cast_embed(:near)
    end
  end

  test "can define a custom module for params schema" do
    assert %{valid?: false} = SearchUser.from(%{near: %{}})
  end


end
