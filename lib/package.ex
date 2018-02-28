defmodule Package do
  @derive [Poison.Encoder]
  defstruct [:name, :version,:size,:depends]
end

defmodule Dependencies do
	@derive [Poison.Encoder]
	defstruct []
end