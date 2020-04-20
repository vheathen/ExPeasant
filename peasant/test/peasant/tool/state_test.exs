defmodule Peasant.Tool.StateTest do
  use Peasant.GeneralCase

  defmodule FakeState do
    use Peasant.Tool.State, no_config: true
  end

  @new_state_required_fields [
    :name,
    :config
  ]

  setup do
    state_params = new_tool()

    state = FakeState.new(state_params)

    assert %FakeState{uuid: _} = state

    [state_params: state_params, state: state]
  end

  describe "Tool State" do
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
                ]} = state_params |> Map.delete(req_field) |> FakeState.new()
      end)
    end

    test "should have :attached field", %{state: state} do
      assert Map.has_key?(state, :attached)
      assert state.attached == false
    end
  end

  defp check_recursive(left, right) do
    Enum.each(left, fn
      {k, v} when is_map(v) ->
        sub = Map.get(right, k)

        refute is_nil(sub),
          message: "Map '#{inspect(right)}' doen't have a required key '#{inspect(k)}'"

        check_recursive(v, sub)

      {k, v} ->
        assert Map.get(right, k) == v
    end)
  end
end
