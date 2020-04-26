defmodule Peasant.Automation.Event.StepRenamed do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:name)
end
