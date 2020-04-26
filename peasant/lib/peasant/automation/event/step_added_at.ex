defmodule Peasant.Automation.Event.StepAddedAt do
  use Peasant.Automation.Event

  event_field(:step)
  event_field(:index)
end
