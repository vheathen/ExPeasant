defmodule Peasant.TestHelper do
  @doc """
  Testing
  """

  use ExUnit.CaseTemplate

  @type fun_descr :: {name :: atom(), arity :: integer()}

  @spec test_protocol(
          protocol :: module(),
          functions :: [fun_descr() | [fun_descr()]]
        ) :: :ok
  def test_protocol(protocol, expected_functions) when is_atom(protocol) do
    assert protocol_defs = protocol.__protocol__(:functions)

    Enum.each(expected_functions, fn
      {_, _} = expected_function ->
        assert has_function?(protocol_defs, expected_function),
          message:
            "Protocol #{protocol} should define #{inspect(expected_function)} function but it defines only #{
              inspect(protocol_defs)
            }"

      fn_list when is_list(fn_list) ->
        assert has_function?(protocol_defs, fn_list),
          message: "Protocol #{protocol} should define one of the following functions:
            #{inspect(fn_list)} but it defines only #{inspect(protocol_defs)}"
    end)

    :ok
  end

  def has_function?(fun_list, {_, _} = expected_fun) when is_list(fun_list) do
    Enum.any?(fun_list, &(&1 == expected_fun))
  end

  def has_function?(fun_list, expected_funs) when is_list(fun_list) and is_list(expected_funs) do
    Enum.reduce_while(expected_funs, false, fn expected_fun, acc ->
      case has_function?(fun_list, expected_fun) do
        false -> {:cont, acc}
        true -> {:halt, true}
      end
    end)
  end

  def check_recursive(left, right) do
    Enum.each(left, fn
      {k, v} when is_map(v) ->
        sub = Map.get(right, k)

        refute is_nil(sub),
          message: "Map '#{inspect(right)}' doen't have a required key '#{inspect(k)}'"

        check_recursive(v, sub)

      {k, v} ->
        assert Map.get(right, k) == v,
          message: "Map\n\n#{inspect(right)}\n\nhas different value for the key #{inspect(k)}"
    end)
  end
end
