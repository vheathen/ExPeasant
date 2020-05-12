defmodule PeasantWeb.AutomationsHelpers do
  @moduledoc false

  alias Peasant.Automations

  @step_type_options Enum.map(
                       Peasant.Automation.State.Step.types(),
                       &{String.capitalize(&1), &1}
                     )

  def step_type_options, do: @step_type_options

  def get_automation(uuid) do
    Automations.get(uuid)
  end

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
