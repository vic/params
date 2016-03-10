defmodule Params.Behaviour do
  @moduledoc false

  @callback from(Map.t, Keyword.t) :: Ecto.Changeset.t
  @callback data(Map.t, Keyword.t) :: Struct.t
  @callback changeset(Ecto.Changeset.t, Map.t) :: Ecto.Changeset.t

end
