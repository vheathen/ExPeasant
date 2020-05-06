defmodule Peasant.Automation.Event.StepDescriptionChanged do
  use Peasant.Automation.Event

  event_field(:step_uuid)
  event_field(:description)
end
