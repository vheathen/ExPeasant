defmodule PeasantWeb.ToolsHelpers do
  @moduledoc false

  alias Peasant.Tools
  import PeasantWeb.ViewHelpers

  def list_actions_for_select(tool_uuid) do
    tool_uuid
    |> Tools.get_actions_by_tool()
    |> Enum.map(&{Atom.to_string(&1), &1})
  end

  def get_tool(uuid), do: Tools.get(uuid)

  def list_tools_for_select(search, limit \\ 100) do
    search
    |> list_tools(:name, :asc, limit)
    |> elem(0)
    |> Enum.map(fn %type{} = tool ->
      {"#{tool.name} | #{shrink_tool_type(type)}", tool.uuid}
    end)
  end

  def list_tools(search, sort_by, sort_dir, limit, offset \\ 0) do
    sorter = if sort_dir == :asc, do: &<=/2, else: &>=/2

    tools = for tool <- Tools.list(), show_tool?(tool, search), do: tool

    count = length(tools)

    tools =
      tools
      |> Enum.sort_by(&Map.get(&1, sort_by), sorter)
      |> Enum.slice(offset, limit)

    {tools, count}
  end

  defp show_tool?(_tool, _search), do: true
end
