defmodule Peasant.Tool.Action.AllActionsDefinitionTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Action

  @actions [
    Action.FakeAction,
    Action.Attach,
    Action.TurnOn,
    Action.TurnOff
  ]

  @expected_funs [
    [run: 2, run: 3],
    resulting_events: 1,
    template: 1
  ]

  test "all actions must define all of the expected funcs" do
    Enum.each(@actions, fn action -> test_protocol(action, @expected_funs) end)
  end
end
