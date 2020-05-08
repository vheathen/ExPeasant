defmodule Peasant.Automation.Event.StepSkipped do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:index)
  event_field(:timestamp)
end
