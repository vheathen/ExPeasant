defmodule Peasant.Fixture do
  import Peasant.Factory

  def new_tool(attrs \\ []), do: build(:new_tool, attrs)

  def new_auto(attrs \\ []), do: build(:new_automation, attrs)

  def new_step(attrs \\ []), do: build(:new_step, attrs)
end
