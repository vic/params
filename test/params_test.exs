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
             _id: :binary_id} ==
      PetParams.__changeset__
  end

  test "defaults to no required fields" do
    assert [] == Params.required PetParams
  end

  test "defaults to all optional fields" do
    assert [:_id, :age, :name] == Params.optional PetParams
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


  test "to_map gets map of struct except for _id" do
    params = %{
      "latitude" => 12.2,
      "longitude" => 13.3
    }
    result = params
              |> LocationParams.from
              |> Params.to_map

    assert result == %{latitude: 12.2, longitude: 13.3}
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
    assert [:near_location, :breed] = Params.required(Params.Kitten)
  end

  test "kitten module has list of optional fields" do
    assert [:age_min, :age_max] = Params.optional(Params.Kitten)
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
      cast(ch, params, ~w(name age))
      |> validate_required([:name])
      |> validate_inclusion(:age, 10..20)
    end

    def changeset(ch, params) do
      cast(ch, params, ~w(name age), ~w())
      |> validate_inclusion(:age, 1..6)
    end
  end

  test "user can populate with custom changeset" do
    assert %{valid?: false} = kid(%{name: "hugo", age: 5}, with: &Params.Kid.custom/2)
  end

  test "user can override changeset" do
    assert %{valid?: true} = kid(%{name: "hugo", age: 5})
  end

  test "can obtain data from changeset" do
    m = Params.data kid(%{name: "hugo", age: "5"})
    assert "hugo" == m.name
    assert 5 == m.age
    assert nil == m._id
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
      cast(ch, params, ~w(name))
      |> validate_required([:name])
      |> cast_embed(:near)
    end
  end

  test "can define a custom module for params schema" do
    assert %{valid?: false} = SearchUser.from(%{near: %{}})
  end

  defmodule StringArray do
    use Params.Schema, %{tags!: [:string]}
  end

  test "can have param with array of strings" do
    assert %{valid?: true} = ch = StringArray.from(%{"tags" => ["hello", "world"]})
    assert ["hello", "world"] = Params.data(ch).tags
  end

  defmodule ManyNames do
    use  Params.Schema, %{names!: [%{name!: :string}]}
  end

  test "can have array of embedded schemas" do
    assert %{valid?: true} = ch = ManyNames.from(%{names: [%{name: "Julio"}, %{name: "Cesar"}]})
    assert ["Julio", "Cesar"] = ch |> Params.data |> Map.get(:names) |> Enum.map(&(&1.name))
  end

  defmodule Vowel do
    use Params.Schema, %{x: :string}
    def changeset(ch, params) do
      cast(ch, params, [:x])
      |> validate_required([:x])
      |> validate_inclusion(:x, ~w(a e i o u))
    end
  end

  test "module's data function returns {:ok, data} for valid changeset" do
    assert {:ok, %{__struct__: _, x: _}} = Vowel.data(%{"x" => "a"})
  end

  test "module's data function returns {:error, changeset} for invalid changeset" do
    assert {:error, %Changeset{valid?: false}} = Vowel.data(%{"x" => "x"})
  end

  defparams schema_options %{
    foo: [field: :string, default: "FOO"]
  }

  test "can specify raw Ecto.Schema options like default using a keyword list" do
    ch = schema_options(%{})
    assert ch.valid?
    m = Params.data(ch)
    assert m.foo == "FOO"
  end

  test "gets default values with to_map" do
    changeset = schema_options(%{})
    map = Params.to_map(changeset)
    assert map == %{foo: "FOO"}
  end

  defparams default_nested %{
    foo: %{
      bar: :string,
      baz: :string
    },
    bat: %{
      man: [field: :string, default: "BATMAN"],
      wo: %{
        man: [field: :string, default: "BATWOMAN"]
      },
      mo: %{ vil: :string }
    }
  }

  test "embeds with defaults are not nil" do
    ch = default_nested(%{})
    assert ch.valid?
    m = Params.data(ch)
    assert m.bat.man == "BATMAN"
    assert m.bat.wo.man == "BATWOMAN"
    assert %{mo: nil} = m.bat
    assert nil == m.foo
  end

  test "to_map works on nested schemas with default values and empty input" do
    changeset = %{} |> default_nested

    assert changeset.valid?
    result = Params.to_map(changeset)

    assert result == %{
      bat: %{
        man: "BATMAN",
        wo: %{
          man: "BATWOMAN"
        }
      }
    }
  end

  test "to_map works on nested schemas with default values" do
    changeset = %{
      bat: %{
        man: "Bruce"
      }
    }
    |> default_nested

    assert changeset.valid?
    result = Params.to_map(changeset)

    assert result == %{
      bat: %{
        man: "Bruce",
        wo: %{
          man: "BATWOMAN"
        }
      }
    }
  end

  defmodule DefaultNested do
    use Params.Schema, %{
      a: :string,
      b: :string,
      c: [field: :string, default: "C"],
      d: %{
        e: :string,
        f: :string,
        g: [field: :string, default: "G"],
      },
      h: %{
        i: :string,
        j: :string,
        k: [field: :string, default: "K"],
      },
      l: %{
        m: :string
      },
      n: %{
        o: %{
          p: [field: :string, default: "P"]
        }
      }

    }
  end

  test "to_map only returns submitted fields" do
    result = %{
      a: "A",
      d: %{
        e: "E",
        g: "g"
      }
    }
    |> DefaultNested.from
    |> Params.to_map

    assert result == %{
      a: "A",
      c: "C",
      d: %{
        e: "E",
        g: "g"
      },
      h: %{
        k: "K"
      },
      n: %{
        o: %{
          p: "P"
        }
      }
    }
  end
end
