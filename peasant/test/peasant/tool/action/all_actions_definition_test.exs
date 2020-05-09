defmodule Peasant.Tool.Action.AllActionsDefinitionTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Action
  alias Peasant.Tools

  @actions [
             Action.FakeAction,
             Action.Attach,
             Action.TurnOn,
             Action.TurnOff
           ]
           |> Enum.sort()

  @expected_funs [
    [run: 2, run: 3],
    resulting_events: 1,
    template: 1,
    persist_after?: 1
  ]

  test "all actions must define all of the expected funcs" do
    Enum.each(@actions, fn action -> test_protocol(action, @expected_funs) end)
  end

  test "all actions must be loaded on start" do
    assert Peasant.system_state() == :ready
    assert @actions == Tools.actions() |> Map.keys() |> Enum.sort()
  end
end
