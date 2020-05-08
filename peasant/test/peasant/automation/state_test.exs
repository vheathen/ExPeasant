defmodule Peasant.Automation.StateTest do
  use Peasant.GeneralCase

  alias Peasant.Automation.State

  @new_state_required_fields [
    :name
  ]

  setup do
    state_params = new_automation()

    state = State.new(state_params)
    assert %State{uuid: _} = state

    [state_params: state_params, state: state]
  end

  describe "Automation State" do
    @describetag :unit

    test "should have used Peasant.Schema as a basement", do: :ok

    test "should cast all fields", %{state_params: state_params, state: state} do
      check_recursive(state_params, state)
    end

    test "should return an error if there is no required field", %{state_params: state_params} do
      Enum.each(@new_state_required_fields, fn req_field ->
        assert {:error,
                [
                  {
                    ^req_field,
                    {"can't be blank", [validation: :required]}
                  }
                ]} = state_params |> Map.delete(req_field) |> State.new()
      end)
    end

    test "should have :steps field", %{state: state} do
      assert Map.has_key?(state, :steps)
      assert state.steps == []
    end

    test "should have :active field", %{state: state} do
      assert Map.has_key?(state, :active)
      assert state.active == false
    end

    test "should have :new virtual field", %{state: state} do
      assert Map.has_key?(state, :new)
      assert state.new == true
      refute :new in State.__schema__(:fields)
    end

    test "should have timestamps", %{state: state} do
      assert Map.has_key?(state, :inserted_at)
      assert Map.has_key?(state, :updated_at)
    end

    test "should have :total_steps virtual field", %{state: state} do
      assert Map.has_key?(state, :total_steps)
      assert state.total_steps == 0
      refute :total_steps in State.__schema__(:fields)
    end

    test "should have :last_step_index field", %{state: state} do
      assert Map.has_key?(state, :last_step_index)
      assert state.last_step_index == -1
    end

    test "should have :last_step_attempted_at field", %{state: state} do
      assert Map.has_key?(state, :last_step_attempted_at)
      assert state.last_step_attempted_at == 0
    end

    test "should have :timer virtual field", %{state: state} do
      assert Map.has_key?(state, :timer)
      assert state.timer == nil
      refute :timer in State.__schema__(:fields)
    end

    test "should have :timer_ref string virtual field", %{state: state} do
      assert Map.has_key?(state, :timer_ref)
      assert state.timer_ref == nil
      refute :timer_ref in State.__schema__(:fields)
    end
  end
end
