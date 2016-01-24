# Params

Easily define parameter structure and validate/cast with [Ecto.Schema][Ecto.Schema]

- [About](#About)
- [Installation](#Installation)
- [Usage](#Usage)

## About

If you've been doing [Ecto][Ecto] based applications lately,
you know Ecto provides a very easy way to populate your models with data comming
from request parameters, validating and casting their values along the way.

All this thanks to the [Ecto.Schema][Ecto.Schema] and [Ecto.Changeset][cast] modules.
The first specifies the fields your model has (tipically the same as your db table)
and the later provides an easy way to convert potentially unsafe data and validate
stuff via changesets.

So for example, in a tipical [Phoenix][Phoenix] application, a `User` model
would look like:

```elixir
defmodule MyApp.User do
   use MyApp.Web, :model

   schema "users" do
     field :name, :string
     field :age,  :integer
   end

   @required ~(name)
   @optional ~(age)

   def changeset(changeset_or_model, params) do
     cast(changeset_or_model, params, @required, @optional)
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
wont even be persisted into a database. All you need is just specify a module and
define your schema, [Ecto.Changeset][cast] will be happy to work with it.

This comes handy when you have certain parameter structure you want
to enforce for example if you are developing a REST API.

Some Rails developers might be right now wondering where their
_strong parameters_ can be defined. On Elixir land, there's no need for
such a thing, as we will see, just using an `Ecto.Schema` with `Ecto.Changeset`
can be much more powerful.

So, for example, suppose your API performs a search for kittens looking for
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
    cast(ch, params, @required, @optional)
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
    embeds_one :near_location, Location
  end

  def changeset(ch, params) do
    cast(ch, params, @required, @optional)
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

That would work, however it's still a lot of code,
just for creating parameter schemas and changesets.

[Params](#Usage) is just a simple [Ecto.Schema][Ecto.Schema]
wrapper for reducing all this boilerplate, while still
leting you create custom changesets for parameter processing.

## Installation

[Available in Hex](https://hex.pm/packages/params), the package can be installed as:

  1. Add params to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:params, "~> 0.0.1"}]
end
```

## Usage

Using `Params.Schema` the previous example would look like:

```elixir
defmodule MyAPI.Params.Location do
  use Params.Schema
  @required ~w(latitude longitude)
  schema do
    field :latitude,  :float
    field :longitude, :float
  end
end

defmodule MyAPI.Params.KittenSearch do
  use Params.Schema
  @required ~w(breed near_location)
  @optional ~w(age_min age_max)
  schema do
    field :breed, :string
    field :age_min, :integer
    field :age_max, :integer
    embeds_one :near_location, Location
  end
end
```

By default if you dont specify an `@required`
module attribute, all defined fields will be
taken as `@optional`, allowing your module
to just work. You also dont need to specify
a `changeset` method (but you can overrive it though).

The default generated `changeset` method, just
takes the `@required` and `@optional` lists
and correctly populates embedded schemas.

On you controller:

```elixir

# Obtain a changeset from the params dict
changeset = MyAPI.Params.KittenSearch.from(params)

# the changeset will be valid if all nested
# schemas are also valid and if casting was ok
changeset.valid?

# You can also obtain a dict back from
# casted and cleaned data changes
changes = MyAPI.Params.KittenSearch.changes(params)
```


[Phoenix]: http://www.phoenixframework.org
[Ecto]: https://hexdocs.pm/ecto
[Ecto.Schema]: https://hexdocs.pm/ecto/Ecto.Schema.html
[cast]: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4
