defmodule Peasant.Fixture do
  import Peasant.Factory

  alias Peasant.Automation.State.Step

  def new_tool(attrs \\ []), do: build(:new_tool, attrs)

  def new_automation(attrs \\ []), do: build(:new_automation, attrs)

  def new_step(attrs \\ [])

  def new_step(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> new_step()

  def new_step(%{type: "awaiting"} = attrs), do: build(:new_step_awaiting, attrs)
  def new_step(attrs), do: build(:new_step, attrs)
  def new_step_struct(attrs \\ []), do: attrs |> new_step() |> Step.new()
end
