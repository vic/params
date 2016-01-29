defmodule Params.Behaviour do

  @callback from(Map.t, Atom.t) :: Ecto.Changeset.t
  @callback changeset(Ecto.Changeset.t, Map.t) :: Ecto.Changeset.t

end
