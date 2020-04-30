defmodule Peasant.AutomationInActionTest do
  use Peasant.GeneralCase

  alias Peasant.Automation
  alias Peasant.Automation.Event, as: AE

  alias Peasant.Tool
  alias Peasant.Tool.Action
  alias Peasant.Tool.Event, as: TE

  # require Logger

  @time_to_wait 50

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  describe "automation scenario" do
    @describetag :integration

    setup do
      Peasant.subscribe(@tools)
      Peasant.subscribe(@automations)
    end

    setup do
      assert {:ok, check_pin_r1} = Circuits.GPIO.open(1, :input)
      assert {:ok, check_pin_r2} = Circuits.GPIO.open(3, :input)

      assert {:ok, r1} = Tool.register(Peasant.Tools.SimpleRelay, new_tool(config: %{pin: 0}))
      assert_receive %TE.Registered{tool_uuid: ^r1}

      assert {:ok, _ref} = Tool.commit(r1, Action.Attach)
      assert_receive %TE.Attached{tool_uuid: ^r1}

      assert {:ok, _ref} = Tool.commit(r1, Action.TurnOff)
      assert_receive %TE.TurnedOff{tool_uuid: ^r1}

      assert {:ok, r2} = Tool.register(Peasant.Tools.SimpleRelay, new_tool(config: %{pin: 2}))
      assert_receive %TE.Registered{tool_uuid: ^r2}

      assert {:ok, _ref} = Tool.commit(r2, Action.Attach)
      assert_receive %TE.Attached{tool_uuid: ^r2}

      assert {:ok, _ref} = Tool.commit(r2, Action.TurnOff)
      assert_receive %TE.TurnedOff{tool_uuid: ^r2}

      automation_spec = new_automation()
      assert {:ok, a1} = Automation.create(automation_spec)
      assert_receive %AE.Created{automation_uuid: ^a1}

      s1 = new_step(tool_uuid: r1, action: Action.TurnOn, active: true)
      s2 = new_step(tool_uuid: r2, action: Action.TurnOn, active: true)
      s3 = new_step(type: "awaiting", time_to_wait: @time_to_wait, active: true)
      s4 = new_step(tool_uuid: r2, action: Action.TurnOff, active: true)
      s5 = new_step(type: "awaiting", time_to_wait: @time_to_wait, active: true)
      s6 = new_step(tool_uuid: r1, action: Action.TurnOff, active: true)
      s7 = new_step(type: "awaiting", time_to_wait: @time_to_wait, active: true)

      [s1u, s2u, s3u, s4u, s5u, s6u, s7u] =
        [s1, s2, s3, s4, s5, s6, s7]
        |> Enum.map(fn step ->
          assert {:ok, step_uuid} = Automation.add_step_at(a1, step, :last)

          assert_receive %AE.StepAddedAt{
            automation_uuid: a1,
            step: %{uuid: ^step_uuid},
            index: -1
          }

          step_uuid
        end)

      assert Circuits.GPIO.read(check_pin_r1) == 0
      assert Circuits.GPIO.read(check_pin_r2) == 0

      # on_exit(fn ->
      # end)

      assert :ok = Automation.activate(a1)
      assert_receive %AE.Activated{automation_uuid: ^a1}

      [
        r1: r1,
        r2: r2,
        check_pin_r1: check_pin_r1,
        check_pin_r2: check_pin_r2,
        a1: a1,
        steps: [s1u, s2u, s3u, s4u, s5u, s6u, s7u]
      ]
    end

    test "should work",
         %{
           a1: a1,
           steps: [_s1u, _s2u, _s3u, _s4u, _s5u, _s6u, s7u]
         } = context do
      #

      1..5
      |> Enum.each(fn _ ->
        cycle_check(context)
        assert_receive %AE.StepStopped{step_uuid: ^s7u, step_duration: _duration}
      end)

      # try to do it alone
      cycle_check(context)

      # and deactivate automation before the last step (waiting) finished
      assert :ok = Automation.deactivate(a1)

      assert_receive %AE.StepStopped{step_uuid: ^s7u, step_duration: duration}

      assert_receive %AE.Deactivated{automation_uuid: ^a1}, 1_000

      assert duration < @time_to_wait

      # Logger.warn("s7 pause actual duration: #{duration}")
    end
  end

  def cycle_check(%{
        r1: r1,
        r2: r2,
        check_pin_r1: check_pin_r1,
        check_pin_r2: check_pin_r2,
        steps: [s1u, s2u, s3u, s4u, s5u, s6u, s7u]
      }) do
    assert_receive %AE.StepStarted{step_uuid: ^s1u}
    assert_receive %AE.StepStopped{step_uuid: ^s1u}
    assert_receive %TE.TurnedOn{tool_uuid: ^r1}
    refute_received %TE.TurnedOff{tool_uuid: ^r1}

    assert_receive %AE.StepStarted{step_uuid: ^s2u}
    assert_receive %AE.StepStopped{step_uuid: ^s2u}
    assert_receive %TE.TurnedOn{tool_uuid: ^r2}
    refute_received %TE.TurnedOff{tool_uuid: ^r2}

    assert_receive %AE.StepStarted{step_uuid: ^s3u}

    refute_received %TE.TurnedOn{tool_uuid: ^r1}
    refute_received %TE.TurnedOff{tool_uuid: ^r1}
    refute_received %TE.TurnedOn{tool_uuid: ^r2}
    refute_received %TE.TurnedOff{tool_uuid: ^r2}

    1..4
    |> Enum.each(fn _ ->
      Process.sleep(10)
      assert Circuits.GPIO.read(check_pin_r1) == 1
      assert Circuits.GPIO.read(check_pin_r2) == 1

      refute_received %AE.StepStopped{step_uuid: ^s3u}
    end)

    assert_receive %AE.StepStopped{step_uuid: ^s3u, step_duration: duration}

    # Logger.warn("s3 pause actual duration: #{duration}")

    assert_receive %AE.StepStarted{step_uuid: ^s4u}
    assert_receive %AE.StepStopped{step_uuid: ^s4u}
    assert_receive %TE.TurnedOff{tool_uuid: ^r2}

    assert_receive %AE.StepStarted{step_uuid: ^s5u}

    1..4
    |> Enum.each(fn _ ->
      Process.sleep(10)
      assert Circuits.GPIO.read(check_pin_r1) == 1
      assert Circuits.GPIO.read(check_pin_r2) == 0

      refute_received %AE.StepStopped{step_uuid: ^s5u}
    end)

    assert_receive %AE.StepStopped{step_uuid: ^s5u, step_duration: duration}

    # Logger.warn("s5 pause actual duration: #{duration}")

    assert_receive %AE.StepStarted{step_uuid: ^s6u}
    assert_receive %AE.StepStopped{step_uuid: ^s6u}
    assert_receive %TE.TurnedOff{tool_uuid: ^r1}

    assert_receive %AE.StepStarted{step_uuid: ^s7u}

    refute_received %TE.TurnedOn{tool_uuid: ^r1}
    refute_received %TE.TurnedOff{tool_uuid: ^r1}
    refute_received %TE.TurnedOn{tool_uuid: ^r2}
    refute_received %TE.TurnedOff{tool_uuid: ^r2}

    1..3
    |> Enum.each(fn _ ->
      Process.sleep(10)
      assert Circuits.GPIO.read(check_pin_r1) == 0
      assert Circuits.GPIO.read(check_pin_r2) == 0

      refute_received %AE.StepStopped{step_uuid: ^s7u}
    end)
  end
end
