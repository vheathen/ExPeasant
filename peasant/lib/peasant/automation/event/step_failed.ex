defmodule Peasant.Automation.Event.StepFailed do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:step_position)
  event_field(:timestamp)
  event_field(:step_duration)
  event_field(:details)
end
