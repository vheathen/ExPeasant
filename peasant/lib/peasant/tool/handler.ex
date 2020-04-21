defmodule Peasant.Tool.Handler do
  @moduledoc false

  use GenServer

  import Peasant.Helper

  @domain "tools"

  ###
  # Internal Public API
  #

  def start_link(%{uuid: tool_uuid} = tool),
    do: GenServer.start_link(__MODULE__, tool, name: via_tuple(tool_uuid))

  def register(tool),
    do: __MODULE__ |> handler_child_spec(tool) |> Peasant.Toolbox.add()

  def attach(tool_uuid) do
    case Registry.lookup(Peasant.Registry, tool_uuid) do
      [] -> {:error, :no_tool_exists}
      _ -> GenServer.cast(via_tuple(tool_uuid), :attach)
    end
  end

  ####
  # Implementation

  def init(tool) do
    {:ok, tool, {:continue, :registered}}
  end

  def handle_continue(:registered, %handler{} = tool) do
    event = new_event([tool: tool], Registered, handler)
    notify(event)

    {:noreply, tool}
  end

  def handle_cast(:attach, %{attached: true} = tool), do: {:noreply, tool}

  def handle_cast(:attach, %handler{} = tool) do
    {tool, event} =
      case handler.do_attach(tool) do
        {:ok, tool} ->
          tool = %{tool | attached: true}
          event = new_event([tool: tool], Attached, handler)
          {tool, event}

        {:error, reason} ->
          event = new_event([tool_uuid: tool.uuid, reason: reason], AttachmentFailed, handler)
          {tool, event}
      end

    notify(event)

    {:noreply, tool}
  end

  defp new_event(details, event, handler), do: Module.concat(handler, event).new(details)
  defp notify(event), do: Peasant.broadcast(@domain, event)
end
