defmodule Peasant.Tool do
  @moduledoc """
  - A tool Behavior description
  - Local tool API
  - The Tool namespace
  """

  @opaque t() :: Peasant.Tool.State.t()

  @tool_handler_default Peasant.Tool.Handler

  @spec register(atom(), map()) ::
          {:ok, Ecto.UUID}
          | {:error, term()}
  def register(tool_module, tool_spec) do
    case tool_module.new(tool_spec) do
      {:error, _error} = error ->
        error

      tool ->
        tool_handler().register(tool)
        {:ok, tool.uuid}
    end
  end

  @spec commit(tool_uuid :: Ecto.UUID, action :: Peasant.Tool.Action.t(), action_config :: map()) ::
          {:ok, Peasant.Tool.Action.action_ref()}
          | {:error, :action_not_supported}
          | {:error, :not_attached}
          | {:error, term()}
  def commit(tool_uuid, action, action_config \\ %{}),
    do: tool_handler().commit(tool_uuid, action, action_config)

  @spec tool_handler :: Peasant.Tool.Handler
  @doc false
  def tool_handler do
    Application.get_env(:peasant, :tool_handler, @tool_handler_default)
  end
end
