defmodule Peasant.Automations do
  @moduledoc false

  @automations Peasant.Automation.domain()

  def list, do: Peasant.Repo.list(@automations)
end
