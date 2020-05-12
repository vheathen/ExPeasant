defmodule Peasant.Collection.Observer do
  use GenServer, restart: :transient

  alias Peasant.Collection.Keeper
  alias Peasant.Repo

  require Logger

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  @tool_to_actions "tta"
  @action_to_tools "att"

  @default_state :loading

  def current_state, do: :sys.get_state(__MODULE__)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, @default_state, {:continue, :load}}
  end

  def handle_continue(:load, collection) do
    for {_id, {domain, record}} <- Keeper.get_all() do
      Repo.put(record, record.uuid, domain, persist: false)
    end

    {:noreply, collection, {:continue, :get_actions}}
  end

  def handle_continue(:get_actions, collection) do
    get_actions()

    {:noreply, collection, {:continue, :populate}}
  end

  def handle_continue(:populate, _collection) do
    for tool <- Repo.list(@tools) do
      Peasant.Tool.Handler.register(tool)
    end

    for automation <- Repo.list(@automations) do
      Peasant.Automation.Handler.create(automation)
    end

    {:noreply, :ready}
  end

  # pass all other events
  def handle_info(_, collection), do: {:noreply, collection}

  #### Support funcs

  defp get_actions do
    :peasant
    |> Application.get_env(Actions)
    |> get_actions()

    spread_actions_for_any()

    sort_tools_and_actions()
  end

  # defp get_action(config) when is_list(config) do
  #   action? =
  #     fn action, namespace ->
  #       prefix = Atom.to_string(namespace)
  #       action |> Atom.to_string() |> String.starts_with?(prefix)
  #     end

  #   for {app, namespace} <- config,
  #     action <- Protocol.extract_protocols([:code.lib_dir(app, :ebin)]),
  #       action?.(action, namespace),
  #         tool <- action.__protocol__(:impls) do
  #           supported_actions = Repo.get(tool, @tool_to_actions) || []

  #             if action in supported_actions,
  #               do: supported_actions,
  #               else: [action | supported_actions]
  #             |> Repo.put(tool, @tool_to_actions, persist: false)
  #         end
  # end

  defp get_actions([{app, namespace} | rest]) do
    prefix = Atom.to_string(namespace)

    [:code.lib_dir(app, :ebin)]
    |> Protocol.extract_protocols()
    |> load_actions(prefix)

    get_actions(rest)
  end

  defp get_actions([]), do: :ok

  defp get_actions(_),
    do:
      raise(
        "Can't find Actions. Don't forget to add config :peasant, Actions, app => namespace into config.exs"
      )

  defp load_actions([action | actions], prefix) do
    case action |> Atom.to_string() |> String.starts_with?(prefix) do
      true ->
        action
        |> get_supported_tools()
        |> load_supported_tools(action)

      false ->
        :ok
    end

    load_actions(actions, prefix)
  end

  defp load_actions([], _prefix), do: :ok

  defp load_supported_tools({:consolidated, tools}, action),
    do: load_supported_tools(tools, action)

  defp load_supported_tools(:not_consolidated, _action),
    do: raise("To support actions Protocols must be consolidated!")

  defp load_supported_tools([tool | tools], action) do
    (Repo.get(tool, @tool_to_actions) || [])
    |> List.insert_at(0, action)
    |> Repo.put(tool, @tool_to_actions, persist: false)

    (Repo.get(action, @action_to_tools) || [])
    |> List.insert_at(0, tool)
    |> Repo.put(action, @action_to_tools, persist: false)

    load_supported_tools(tools, action)
  end

  defp load_supported_tools([], _action), do: :ok

  defp get_supported_tools(action), do: action.__protocol__(:impls)

  defp spread_actions_for_any do
    {actions_for_any_list, tool_types} =
      @tool_to_actions
      |> Repo.list_full()
      |> Map.pop(Any)

    tool_types_list = Map.keys(tool_types)

    Enum.each(
      actions_for_any_list,
      &Repo.put(tool_types_list, &1, @action_to_tools, persist: false)
    )

    Repo.delete(Any, @tool_to_actions, persist: false)

    Enum.each(
      tool_types,
      fn {tool, actions} ->
        Repo.put(actions ++ actions_for_any_list, tool, @tool_to_actions, persist: false)
      end
    )
  end

  defp sort_tools_and_actions do
    @tool_to_actions
    |> Repo.list_full()
    |> Enum.each(fn {tool, actions} ->
      Repo.put(actions |> Enum.sort() |> Enum.uniq(), tool, @tool_to_actions, persist: false)
    end)

    @action_to_tools
    |> Repo.list_full()
    |> Enum.each(fn {action, tools} ->
      Repo.put(tools |> Enum.sort() |> Enum.uniq(), action, @action_to_tools, persist: false)
    end)
  end
end
