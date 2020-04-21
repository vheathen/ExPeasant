defmodule Peasant.Tool do
  @moduledoc """
  - A tool Behavior description
  - Local tool API
  - The Tool namespace
  """

  @callback do_attach(tool :: %{:uuid => String.t(), optional(atom()) => term()}) ::
              {:ok, struct()}
              | {:error, term()}

  @tool_handler_default Peasant.Tool.Handler

  defmacro __using__(_env) do
    quote do
      use Peasant.Tool.State

      require Logger

      @behaviour unquote(__MODULE__)

      @spec register(tool_spec :: map()) :: {:ok, Ecto.UUID} | {:error, term()}
      def register(tool_spec), do: unquote(__MODULE__).register(__MODULE__, tool_spec)
      def attach(tool_uuid), do: unquote(__MODULE__).attach(tool_uuid)

      def do_attach(tool) do
        # raise(FunctionClauseError,
        #   message: "#{__MODULE__} must have implemented do_attach/1 callback"
        # )

        Logger.warn(
          "#{__MODULE__} doesn't have do_attach/1 callback implementation, just passing by"
        )

        {:ok, tool}
      end

      defoverridable do_attach: 1

      import unquote(__MODULE__)
      require unquote(__MODULE__)

      standard_events([
        {Registered, [:tool]},
        {Attached, [:tool]},
        {AttachmentFailed, [:tool_uuid, :reason]}
      ])

      build_standard_events()
    end
  end

  @spec register(atom(), map()) ::
          {:ok, Ecto.UUID}
          | {:error, term()}
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

  @spec attach(tool_uuid :: Ecto.UUID) ::
          :ok
          | {:error, :no_tool_exists}
  def attach(tool_uuid) do
    tool_handler().attach(tool_uuid)
  end

  @spec tool_handler ::
          Peasant.Tool.Handler
  def tool_handler do
    Application.get_env(:peasant, :tool_handler, @tool_handler_default)
  end

  ##### Macros

  defmacro standard_events(events) do
    quote do
      @standard_events unquote(events)
    end
  end

  defmacro build_standard_events() do
    quote do
      Enum.map(@standard_events, fn {event, fields} ->
        defmodule Module.concat(__MODULE__, event) do
          defstruct fields
          def new(attrs), do: struct(__MODULE__, attrs)
        end
      end)
    end
  end
end
