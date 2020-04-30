defmodule Peasant.Tool.Handler do
  @moduledoc false

  use GenServer

  import Peasant.Helper

  alias Peasant.Tool.Action.Attach

  @tools Peasant.Tool.domain()

  ###
  # Internal Public API
  #

  def start_link(%{uuid: tool_uuid} = tool),
    do: GenServer.start_link(__MODULE__, tool, name: via_tuple(tool_uuid))

  def register(tool),
    do: __MODULE__ |> handler_child_spec(tool) |> Peasant.Toolbox.add()

  def commit(tool_uuid, action, action_config) do
    try do
      GenServer.call(via_tuple(tool_uuid), {:commit, action, action_config})
    catch
      :exit, {:noproc, _} -> {:error, :no_tool_exists}
    end
  end

  ####
  # Implementation

  def init(%{new: true} = tool) do
    {:ok, %{tool | new: false}, {:continue, :registered}}
  end

  def init(%{new: false} = tool) do
    {:ok, tool, {:continue, :loaded}}
  end

  def handle_continue(:registered, %_{} = tool) do
    event = Peasant.Tool.Event.Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})
    notify(event)

    {:noreply, tool}
  end

  def handle_continue(:loaded, %_{} = tool) do
    event = Peasant.Tool.Event.Loaded.new(tool_uuid: tool.uuid, details: %{tool: tool})
    notify(event)

    {:noreply, tool}
  end

  def handle_continue({:commit, action, action_config, action_ref}, tool) do
    {:ok, tool, events} =
      case action.template(tool) do
        nil -> action.run(tool, action_ref)
        t when t == %{} -> action.run(tool, action_ref)
        _ -> action.run(tool, action_ref, action_config)
      end

    notify(events)

    {:noreply, tool}
  end

  def handle_call({:commit, action, action_config}, _from, %type{attached: attached} = tool)
      when attached == true or
             (attached == false and action == Attach) do
    case action.impl_for(tool) do
      nil ->
        {:reply, {:error, [{type, :action_not_supported}]}, tool}

      _ ->
        action_ref = action_ref()

        {:reply, {:ok, action_ref}, tool,
         {:continue, {:commit, action, action_config, action_ref}}}
    end
  end

  def handle_call({:commit, _action, _action_config}, _from, %{attached: false} = tool),
    do: {:reply, {:error, :not_attached}, tool}

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@tools, event)

  defp action_ref, do: UUID.uuid4()
end
