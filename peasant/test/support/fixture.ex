defmodule Peasant.Fixture do
  import Peasant.Factory

  def new_tool(attrs \\ %{}), do: build(:new_tool, attrs)
end
