defmodule Peasant.Automation.Event.StepMovedTo do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:index)
end
