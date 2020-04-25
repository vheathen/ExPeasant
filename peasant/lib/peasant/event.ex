defmodule Peasant.Event do
  defmacro event_field(name) do
    quote do
      Peasant.Event.__event_field__(__MODULE__, unquote(name))
    end
  end

  defmacro event_fields(name_list) do
    quote do
      Enum.map(unquote(name_list), fn name ->
        Peasant.Event.__event_field__(__MODULE__, name)
      end)
    end
  end

  defmacro __using__(_) do
    quote do
      import Peasant.Event, only: [event_field: 1, event_fields: 1]

      @before_compile Peasant.Event

      Module.register_attribute(__MODULE__, :event_fields, accumulate: true)

      @spec new(params :: map() | keyword()) ::
              Event.t()
      def new(params), do: struct(__MODULE__, params)

      defoverridable(new: 1)
    end
  end

  defmacro __before_compile__(_) do
    quote unquote: false do
      defstruct @event_fields
    end
  end

  def __event_field__(module, name) do
    Module.put_attribute(module, :event_fields, name)
  end
end
