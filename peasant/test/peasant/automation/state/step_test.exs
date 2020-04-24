defmodule Peasant.Automation.State.StepTest do
  use Peasant.DataCase

  alias Peasant.Automation.State.Step

  @new_step_required_fields [
    :name,
    :tool_uuid,
    :action
  ]

  setup do
    step_params = new_step()

    step = Step.new(step_params)
    assert %Step{uuid: _} = step

    [step_params: step_params, step: step]
  end

  describe "Automation Step" do
    @describetag :unit

    test "should have used Peasant.Schema as a basement", do: :ok

    test "should cast all fields", %{step_params: step_params, step: step} do
      check_recursive(step_params, step)
    end

    test "should return an error if there is no required field", %{step_params: step_params} do
      Enum.each(@new_step_required_fields, fn req_field ->
        assert {:error,
                [
                  {
                    ^req_field,
                    {"can't be blank", [validation: :required]}
                  }
                ]} = step_params |> Map.delete(req_field) |> Step.new()
      end)
    end

    test "should have :wait_for_events field", %{step: step} do
      assert Map.has_key?(step, :wait_for_events)
      assert step.wait_for_events == false
    end

    test "should have :active field", %{step: step} do
      assert Map.has_key?(step, :active)
      assert step.active == false
    end

    test "should have :suspended_by_tool field", %{step: step} do
      assert Map.has_key?(step, :suspended_by_tool)
      assert step.suspended_by_tool == false
    end

    test "should return error on non-existing action" do
      spec = new_step(action: SomeNonExistedAtom)
      assert {:error, [action: {"doesn't exist", [validation: :action]}]} == Step.new(spec)

      spec = new_step(action: %{})

      assert {:error, [action: {"not an atom or string", [validation: :action]}]} ==
               Step.new(spec)
    end
  end
end
