defmodule Peasant.Tool do
  @moduledoc """
  - A tool Behavior description
  - Local tool API
  - The Tool namespace
  """

  defmacro __using__(_env) do
    quote do
      use Peasant.Tool.State

      # @behaviour unquote(__MODULE__)

      @spec register(tool_spec :: map()) :: {:ok, Ecto.UUID} | {:error, term()}
      def register(tool_spec), do: unquote(__MODULE__).register(__MODULE__, tool_spec)
    end
  end

  alias Peasant.Tool.Handler

  def register(tool_module, tool_spec) do
    {:error, [name: {"can't be blank", [validation: :required]}]}

    case tool_module.new(tool_spec) do
      {:error, _error} = error ->
        error

      tool ->
        Handler.register(tool)
        {:ok, tool.uuid}
    end
  end
end
