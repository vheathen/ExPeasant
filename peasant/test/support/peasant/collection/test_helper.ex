defmodule Peasant.Collection.TestHelper do
  use ExUnit.CaseTemplate

  # import Peasant.Factory
  import Peasant.Fixture

  alias Peasant.Repo

  alias Peasant.Tools.FakeTool

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  def collection_setup(_context) do
    tools =
      0..1
      |> Enum.map(fn _ ->
        tool = new_tool() |> FakeTool.new() |> Map.put(:new, false)
        Repo.put(tool, tool.uuid, @tools)
      end)
      |> Enum.sort()

    assert tools == Repo.list(@tools) |> Enum.sort()

    automations =
      0..1
      |> Enum.map(fn _ ->
        automation = new_automation() |> Peasant.Automation.State.new() |> Map.put(:new, false)
        Repo.put(automation, automation.uuid, @automations)
      end)
      |> Enum.sort()

    assert automations == Repo.list(@automations) |> Enum.sort()

    [tools: tools, automations: automations]
  end

  def on_start_collection_setup(_context) do
    Repo.clear(@tools)
    Repo.clear(@automations)

    assert [] == Repo.list(@tools)
    assert [] == Repo.list(@automations)

    :ok = GenServer.stop(Peasant.Collection.Observer)
    start_supervised(Peasant.Collection.Observer)

    # Process.sleep(100)
    assert :ready == Peasant.system_state()

    assert length(Repo.list(@tools)) > 0
    assert length(Repo.list(@automations)) > 0

    :ok
  end

  def notify(event, domain), do: Peasant.broadcast(domain, event)

  def nilify_timestamps(records) when is_list(records),
    do: Enum.map(records, &nilify_timestamps/1)

  def nilify_timestamps(record), do: %{record | inserted_at: nil, updated_at: nil}
end
