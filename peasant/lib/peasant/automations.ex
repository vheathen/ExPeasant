defmodule Peasant.Automations do
  @moduledoc false

  alias Peasant.Automation

  @automations Peasant.Automation.domain()

  def list, do: Peasant.Repo.list(@automations)

  def get(uuid), do: Peasant.Repo.get(uuid, @automations)

  def change_automation(%Automation.State{} = automation, attrs \\ %{}) do
    Automation.State.changeset(automation, attrs)
  end

  def change_automation_step(%Automation.State.Step{} = step, attrs \\ %{}) do
    Automation.State.Step.changeset(step, attrs)
  end
end
