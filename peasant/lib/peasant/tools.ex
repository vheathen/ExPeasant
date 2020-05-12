defmodule Peasant.Tools do
  alias Peasant.Repo

  @tool_to_actions "tta"
  @action_to_tools "att"

  @tools Peasant.Tool.domain()

  def actions, do: Repo.list_full(@action_to_tools)

  def tool_types, do: Repo.list_full(@tool_to_actions)

  def get_actions_by_tool_type(tool_type), do: Repo.get(tool_type, @tool_to_actions)

  def get_actions_by_tool(tool_uuid) do
    tool_uuid
    |> Repo.get(@tools)
    |> Map.get(:__struct__)
    |> Repo.get(@tool_to_actions)
  end

  def list do
    Repo.list(@tools)
  end

  def get(uuid) do
    Repo.get(uuid, @tools)
  end
end
