defmodule Peasant.Automations do
  @moduledoc false

  alias Peasant.Automation

  @automations Peasant.Automation.domain()

  def list, do: Peasant.Repo.list(@automations)

  def get(uuid), do: Peasant.Repo.get(uuid, @automations)

  def change_automation(%Automation.State{} = automation, attrs \\ %{}) do
    Automation.State.changeset(automation, attrs)
  end
end
