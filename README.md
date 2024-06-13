# Params 

[Looking for maintainer](https://github.com/vic/params/issues/new?title=Becoming%20a%20maintainer)

[![Hex Version](https://img.shields.io/hexpm/v/params.svg)](https://hex.pm/packages/params)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/params/)
[![Total Download](https://img.shields.io/hexpm/dt/params.svg)](https://hex.pm/packages/params)
[![License](https://img.shields.io/hexpm/l/params.svg)](https://github.com/vic/params/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/vic/params.svg)](https://github.com/vic/params/commits/master)

Easily define parameter structure and validate/cast with [Ecto.Schema][Ecto.Schema]

- [About](#about)
- [Installation](#installation)
- [Usage](#usage)
- [API Documentation](https://hexdocs.pm/params/)

## Installation

[Available in Hex](https://hex.pm/packages/params), the package can be installed as:

Add params to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:params, "~> 2.0"}
  ]
end
```

## About

If you've been doing [Ecto][Ecto] based applications lately,
you know Ecto provides a very easy way to populate structs with data coming
from request parameters, validating and casting their values along the way.

All this thanks to the [Ecto.Schema][Ecto.Schema] and [Ecto.Changeset][cast] modules.
The first specifies the fields your model has (typically the same as your db table)
and the later provides an easy way to convert potentially unsafe data and validate
stuff via changesets.

So for example, in a typical [Phoenix][Phoenix] application, a `User` model
would look like:

```elixir
defmodule MyApp.User do
   use MyApp.Web, :model

   schema "users" do
     field :name, :string
     field :age,  :integer
   end

   @required [:name]
   @optional [:age]

   def changeset(changeset_or_model, params) do
     cast(changeset_or_model, params, @required ++ @optional)
     |> validate_required(@required)
   end
end
```

Normally, changesets are related to some data that will be persisted into
a database, and your controller would use the `User.changeset` method like:

```elixir
# UserController.ex
def create(conn, params) do
  ch = User.changeset(%User{}, params)
  if ch.valid? do
    ...
end
```

However, you can use `Ecto.Schema` for validating/casting data that
*won't necessarily* be persisted into a database. All you need is just specify a module and
define your schema, [Ecto.Changeset][cast] will be happy to work with it.

This comes handy when you have certain parameter structure you want
to enforce for example when creating a REST API.

Some Rails developers might be right now wondering where their
_strong parameters_ can be defined. On Elixir land, there's no need for such a thing, as we will see, just using an `Ecto.Schema` with `Ecto.Changeset`
can be much more flexible. Using schemas allows not only
specifying which fields we want, but changesets let use
type cast, perform validations on values, etc.

So, for example, suppose your Phoenix based API performs a search for kittens looking for a
home and expects something like:

```json
{
  "breed": "Russian Blue",
  "age_min": 0,
  "age_max": 5,
  "near_location": {
     "latitude": 92.1,
     "longitude": -82.1
  }
}
```

You'd like to validate that your controller has received the correct
params structure, all you need to do is create a couple of modules:

```elixir
defmodule MyApi.Params.Location
  use Ecto.Schema
  import Ecto.Changeset

  @required ~w(latitude longitude)
  @optional ~w()

  schema "location params" do
    field :latitude, :float
    field :longitude, :float
  end

  def changeset(ch, params) do
    cast(ch, params, @required ++ @optional)
    |> validate_required(@required)
  end
end

defmodule MyAPI.Params.KittenSearch
  use Ecto.Schema
  import Ecto.Changeset

  @required ~w(breed)
  @optional ~w(age_min age_max)

  schema "params for kitten search" do
    field :breed, :string
    field :age_min, :integer
    field :age_max, :integer
    field :age_max, :integer
    field :color, Ecto.Enum, values: [:brown, :black, :grey, :unknown],
    embeds_one :near_location, Location
  end

  def changeset(ch, params) do
    cast(ch, params, @required ++ @optional)
    |> validate_required(@required)
    |> cast_embed(:near_location, required: true)
  end
end

# On your controller:
def search(conn, params) do
  alias MyAPI.Params.KittenSearch
  changeset = KittenSearch.changeset(%KittenSearch{}, params)
  if changeset.valid? do
    ...
end
```

That would allow you to take only valid params as you'd
normally have with any other Ecto.Schema module.

However it's still a lot of code, most of it
defining the the changeset, specifying the optional
and required fields, etc.

[Params](#usage) is just a simple [Ecto.Schema][Ecto.Schema]
wrapper for reducing all this boilerplate, while still
leting you create custom changesets for parameter processing.

## Usage

The previous example could be written like:

```elixir
defmodule MyAPI.KittenController do

  use Params

  defparams kitten_search %{
    breed!: :string,
    age_max: :integer,
    age_min: [field: :integer, default: 1],
    color: [field: Ecto.Enum, values: [:brown, :black, :grey, :unknown]],
    near_location!: %{
      latitude!: :float, longitude!: :float
    },
    tags: [:string]
  }

  def index(conn, params) do
    changeset = kitten_search(params)
    if changeset.valid? do
      search = Params.data changeset
      IO.puts search.near_location.latitude
    ...
  end
end
```

The `defparams` macro generates a module for processing
a [params schema](http://hexdocs.pm/params/Params.Schema.html)

By default all fields are optional. You can mark
required fields by ending them with a `!`, of course
the bang is removed from the field definition and is
only used to mark which fields are required by default.

You can also create a module and define
your schema or custom changesets in it:

```elixir
defmodule UserSearch do
  use Params.Schema, %{name: :string, age: :integer}
  import Ecto.Changeset, only: [cast: 3, validate_inclusion: 3]

  def child(ch, params) do
    cast(ch, params, ~w(name age))
    |> validate_inclusion(:age, 1..6)
  end
end

defmodule MyApp.UserController do

  def index(conn, params) do
    changeset = UserSearch.from(params, with: &UserSearch.child/2)
    if changeset.valid? do
      # age in 1..6
  end

end
```

The [Params.data](http://hexdocs.pm/params/Params.html#data/1)
and [Params.to_map](http://hexdocs.pm/params/Params.html#to_map/1) can be useful
for obtaining a struct or map from a changeset.

Note that `Params.data` and `Params.to_map` have different behaviour: `data`
returns a struct which will include all valid params. `to_map` returns a map
that only includes the submitted keys and keys with default values:

```elixir
defmodule UserUpdateParams do
  use Params.Schema, %{
    name: :string,
    age: :integer,
    auditlog: [field: :boolean, default: true]
  }
end

changeset = UserUpdateParams.from(%{name: "John"})

Params.data(changeset) # => %UserUpdateParams{name: "John", age: nil, auditlog: true}
Params.to_map(changeset) # => %{name: "John", auditlog: true}
```

## API Documentation

[API Documentation](https://hexdocs.pm/params/)


[Phoenix]: http://www.phoenixframework.org
[Ecto]: https://hexdocs.pm/ecto
[Ecto.Schema]: https://hexdocs.pm/ecto/Ecto.Schema.html
[cast]: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/3


## Contributors

Here's a list of [awesome people](https://github.com/vic/params/graphs/contributors) who have contributed code to this project.

If you find a bug or want to improve something, please send a pull-request. Thank you!

## Copyright and License

Copyright (c) 2016 Victor Hugo Borja

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [https://www.apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
