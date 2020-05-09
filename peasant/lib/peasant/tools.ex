defmodule Peasant.Tools do
  alias Peasant.Repo

  @tool_to_actions "tta"
  @action_to_tools "att"

  @tools Peasant.Tool.domain()

  def actions do
    Repo.list_full(@action_to_tools)
  end

  def list do
    Repo.list(@tools)
  end

  def get(uuid) do
    Repo.get(uuid, @tools)
  end
end
