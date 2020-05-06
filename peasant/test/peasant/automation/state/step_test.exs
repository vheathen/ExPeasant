defmodule Peasant.Automation.State.StepTest do
  use Peasant.GeneralCase

  alias Peasant.Automation.State.Step

  @base_required_fields []

  @action_required_fields [
    :tool_uuid,
    :action
  ]

  @awaiting_required_fields [
    :time_to_wait
  ]

  @allowed_types [
    "action",
    "awaiting"
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

    test "should have :type field", %{step: step} do
      assert Map.has_key?(step, :type)
      assert step.type == "action"
    end

    test "should validate :type field values" do
      Enum.each(@allowed_types, fn type ->
        assert %Step{type: ^type} = new_step(type: type) |> Step.new()
      end)

      type = Faker.Lorem.word()

      assert {
               :error,
               [
                 type: {
                   "not a proper step type",
                   [validation: :type]
                 }
               ]
             } = new_step(type: type) |> Step.new()

      [Faker.random_between(-10000, 10000), :atom]
      |> Enum.each(fn type ->
        assert {
                 :error,
                 [
                   type: {
                     "is invalid",
                     [{:type, :string}, {:validation, :cast}]
                   }
                 ]
               } == new_step(type: type) |> Step.new()
      end)
    end
  end

  describe "type \"action\"" do
    @describetag :unit

    test "should cast all fields for action", %{step_params: step_params, step: step} do
      check_recursive(step_params, step)
    end

    test "should return an error if there is no required field", %{step_params: step_params} do
      Enum.each(@base_required_fields ++ @action_required_fields, fn req_field ->
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

  describe "type \"awaiting\"" do
    @describetag :unit

    test "should return an error if there is no required field" do
      Enum.each(@base_required_fields ++ @awaiting_required_fields, fn req_field ->
        assert {:error,
                [
                  {
                    ^req_field,
                    {"can't be blank", [validation: :required]}
                  }
                ]} = new_step(type: "awaiting") |> Map.delete(req_field) |> Step.new()
      end)
    end

    test "time_to_wait should be a non-negative integer" do
      assert {:error,
              [
                time_to_wait:
                  {"must be greater than %{number}",
                   [validation: :number, kind: :greater_than, number: _]}
              ]} = new_step(type: "awaiting") |> Map.put(:time_to_wait, -1) |> Step.new()
    end
  end
end
