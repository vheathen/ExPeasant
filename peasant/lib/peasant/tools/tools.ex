defmodule Peasant.Tools do
  alias Peasant.Repo

  @tool_to_actions "tta"
  @action_to_tools "att"

  def actions do
    Repo.list_full(@action_to_tools)
  end
end
