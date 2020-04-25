defmodule Peasant.Automation.Event do
  @type t() :: struct()

  defmacro __using__(_) do
    quote do
      use Peasant.Event

      event_fields([
        :automation_uuid,
        :action_ref
      ])
    end
  end
end
