defmodule Peasant.Automation.Event.StepStarted do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:step_position)
  event_field(:timestamp)
end
