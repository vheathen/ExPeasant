defmodule PeasantWeb.AutomationsHelpers do
  @moduledoc false

  alias Peasant.Automations

  def list_automations(search, sort_by, sort_dir, limit, offset \\ 0) do
    sorter = if sort_dir == :asc, do: &<=/2, else: &>=/2

    automations =
      for automation <- Automations.list(), show_automation?(automation, search), do: automation

    count = length(automations)

    automations =
      automations
      |> Enum.sort_by(&Map.get(&1, sort_by), sorter)
      |> Enum.slice(offset, limit)

    {automations, count}
  end

  defp show_automation?(_automation, _search), do: true
end
