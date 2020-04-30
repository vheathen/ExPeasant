defmodule PeasantWeb.ToolsHelpers do
  @moduledoc false

  alias Peasant.Tools

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
