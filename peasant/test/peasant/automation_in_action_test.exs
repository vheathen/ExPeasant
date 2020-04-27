defmodule Peasant.AutomationInActionTest do
  use Peasant.DataCase

  alias Peasant.Automation
  alias Peasant.Automation.Event, as: AE

  alias Peasant.Tool
  alias Peasant.Tool.Action

  # alias Peasant.Tool.Event, as: TE

  require Logger

  describe "automation scenario" do
    @describetag :integration

    setup do
      Peasant.subscribe("tools")
      Peasant.subscribe("automations")
    end

    test "should work" do
      assert {:ok, check_pin_r1} = Circuits.GPIO.open(1, :input)
      assert {:ok, check_pin_r2} = Circuits.GPIO.open(3, :input)

      assert {:ok, r1} = Tool.register(Peasant.Tools.SimpleRelay, new_tool(config: %{pin: 0}))
      assert {:ok, _ref} = Tool.commit(r1, Action.Attach)
      assert {:ok, r2} = Tool.register(Peasant.Tools.SimpleRelay, new_tool(config: %{pin: 2}))
      assert {:ok, _ref} = Tool.commit(r2, Action.Attach)

      automation_spec = new_automation()
      assert {:ok, a1} = Automation.create(automation_spec)

      s1 = new_step(tool_uuid: r1, action: Action.TurnOn, active: true)
      s2 = new_step(tool_uuid: r2, action: Action.TurnOn, active: true)
      s3 = new_step(type: "awaiting", time_to_wait: 50, active: true)
      s4 = new_step(tool_uuid: r2, action: Action.TurnOff, active: true)
      s5 = new_step(type: "awaiting", time_to_wait: 50, active: true)
      s6 = new_step(tool_uuid: r1, action: Action.TurnOff, active: true)
      s7 = new_step(type: "awaiting", time_to_wait: 50, active: true)

      [s1u, s2u, s3u, s4u, s5u, s6u, s7u] =
        [s1, s2, s3, s4, s5, s6, s7]
        |> Enum.map(fn step ->
          assert {:ok, step_uuid} = Automation.add_step_at(a1, step, :last)
          # assert :ok = Automation.activate_step(a1, step_uuid)
          step_uuid
        end)

      assert Circuits.GPIO.read(check_pin_r1) == 0
      assert Circuits.GPIO.read(check_pin_r2) == 0

      assert :ok = Automation.activate(a1)

      assert_receive %AE.StepStarted{step_uuid: ^s1u}
      assert_receive %AE.StepStopped{step_uuid: ^s1u}

      assert_receive %AE.StepStarted{step_uuid: ^s2u}
      assert_receive %AE.StepStopped{step_uuid: ^s2u}

      assert_receive %AE.StepStarted{step_uuid: ^s3u}

      1..4
      |> Enum.each(fn _ ->
        Process.sleep(10)
        assert Circuits.GPIO.read(check_pin_r1) == 1
        assert Circuits.GPIO.read(check_pin_r2) == 1
      end)

      assert_receive %AE.StepStopped{step_uuid: ^s3u, step_duration: duration}

      Logger.warn("s3 pause actual duration: #{duration}")

      assert_receive %AE.StepStarted{step_uuid: ^s4u}
      assert_receive %AE.StepStopped{step_uuid: ^s4u}

      assert_receive %AE.StepStarted{step_uuid: ^s5u}

      1..4
      |> Enum.each(fn _ ->
        Process.sleep(10)
        assert Circuits.GPIO.read(check_pin_r1) == 1
        assert Circuits.GPIO.read(check_pin_r2) == 0
      end)

      assert_receive %AE.StepStopped{step_uuid: ^s5u, step_duration: duration}

      Logger.warn("s5 pause actual duration: #{duration}")

      assert_receive %AE.StepStarted{step_uuid: ^s6u}
      assert_receive %AE.StepStopped{step_uuid: ^s6u}

      assert_receive %AE.StepStarted{step_uuid: ^s7u}

      1..4
      |> Enum.each(fn _ ->
        Process.sleep(10)
        assert Circuits.GPIO.read(check_pin_r1) == 0
        assert Circuits.GPIO.read(check_pin_r2) == 0
      end)

      assert_receive %AE.StepStopped{step_uuid: ^s7u, step_duration: duration}

      Logger.warn("s7 pause actual duration: #{duration}")

      assert :ok = Automation.deactivate(a1)

      assert_receive %AE.Deactivated{automation_uuid: ^a1}
    end
  end
end
