defmodule Peasant.Tool do
  @moduledoc """
  - A tool Behavior description
  - Local tool API
  - The Tool namespace
  """

  @callback do_attach(tool :: %{uuid: Ecto.UUID}) :: :ok | {:error, term()}

  @tool_handler_default Peasant.Tool.Handler

  defmacro __using__(_env) do
    quote do
      use Peasant.Tool.State

      # @behaviour unquote(__MODULE__)

      @spec register(tool_spec :: map()) :: {:ok, Ecto.UUID} | {:error, term()}
      def register(tool_spec), do: unquote(__MODULE__).register(__MODULE__, tool_spec)
      def attach(tool_uuid), do: unquote(__MODULE__).attach(tool_uuid)

      import unquote(__MODULE__)
      build_standard_events()
    end
  end

  def register(tool_module, tool_spec) do
    {:error, [name: {"can't be blank", [validation: :required]}]}

    case tool_module.new(tool_spec) do
      {:error, _error} = error ->
        error

      tool ->
        tool_handler().register(tool)
        {:ok, tool.uuid}
    end
  end

  def attach(tool_uuid) do
    tool_handler().attach(tool_uuid)
    :ok
  end

  def tool_handler do
    Application.get_env(:peasant, :tool_handler, @tool_handler_default)
  end

  ##### Macros

  defmacro build_standard_events do
    quote do
      build_registered_event()
    end
  end

  defmacro build_registered_event do
    quote do
      defmodule Registered do
        defstruct [:tool]

        def new(tool), do: struct(__MODULE__, %{tool: tool})
      end
    end
  end
end
