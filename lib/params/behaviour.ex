defmodule Params.Behaviour do
  @moduledoc false

  @callback from(map, Keyword.t) :: Ecto.Changeset.t
  @callback data(map, Keyword.t) :: struct
  @callback changeset(Ecto.Changeset.t, map) :: Ecto.Changeset.t

end
