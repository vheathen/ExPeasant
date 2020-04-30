Peasant.subscribe(Peasant.Automation.domain())
Peasant.subscribe(Peasant.Tool.domain())

alias Peasant.Automation
alias Peasant.Automation.Event, as: AE

alias Peasant.Tool
alias Peasant.Tool.Action

time_to_wait = 10_000

r1s = %{config: %{pin: 20}, name: "r1"}
r2s = %{config: %{pin: 21}, name: "r2"}
{:ok, r1} = Tool.register(Peasant.Tools.SimpleRelay, r1s)
{:ok, _ref} = Tool.commit(r1, Action.Attach)
{:ok, r2} = Tool.register(Peasant.Tools.SimpleRelay, r2s)
{:ok, _ref} = Tool.commit(r2, Action.Attach)

a1s = %{name: "TestAuto"}
{:ok, a1} = Automation.create(a1s)

s1 = %{
  action: Action.TurnOn,
  action_config: %{},
  active: true,
  name: "velit",
  tool_uuid: r1,
  type: "action"
}

{:ok, s1u} = Automation.add_step_at(a1, s1, :last)

s2 = %{
  action: Action.TurnOn,
  action_config: %{},
  active: true,
  name: "velit",
  tool_uuid: r2,
  type: "action"
}

{:ok, s2u} = Automation.add_step_at(a1, s2, :last)

s3 = %{
  active: true,
  name: "quaerat",
  time_to_wait: time_to_wait,
  type: "awaiting"
}

{:ok, s3u} = Automation.add_step_at(a1, s3, :last)

s4 = %{
  action: Action.TurnOff,
  action_config: %{},
  active: true,
  name: "velit",
  tool_uuid: r2,
  type: "action"
}

{:ok, s4u} = Automation.add_step_at(a1, s4, :last)

s5 = %{
  active: true,
  name: "quaerat",
  time_to_wait: time_to_wait,
  type: "awaiting"
}

{:ok, s5u} = Automation.add_step_at(a1, s5, :last)

s6 = %{
  action: Action.TurnOff,
  action_config: %{},
  active: true,
  name: "velit",
  tool_uuid: r1,
  type: "action"
}

{:ok, s6u} = Automation.add_step_at(a1, s6, :last)

s7 = %{
  active: true,
  name: "quaerat",
  time_to_wait: time_to_wait,
  type: "awaiting"
}

{:ok, s7u} = Automation.add_step_at(a1, s7, :last)

:ok = Automation.activate(a1)
