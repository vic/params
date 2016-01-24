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
    near!: %{
      latitude: :float,
      longitude: :float
    }
  }


end
