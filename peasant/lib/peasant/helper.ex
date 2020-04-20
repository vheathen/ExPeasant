defmodule Peasant.Helper do
  @moduledoc """
  Various support functions
  """

  @spec via_tuple(any) :: {:via, Registry, {PeasantRegistry, any}}
  def via_tuple(id), do: {:via, Registry, {PeasantRegistry, id}}
end
