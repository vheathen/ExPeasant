defmodule Peasant.Tool.State do
  @moduledoc """
  A structure template to keep a tool state
  """

  defmacro __using__(_opts) do
    quote do
      use Peasant.Schema

      import unquote(__MODULE__)

      @fields [
        [:name, :string, [required: true, cast: true]],
        [:config, :map, [required: true, cast: true]],
        [:placement, :string, [cast: true]],
        [:attached, :boolean, [default: false]],
        [:new, :boolean, [default: true]]
      ]

      translate_to_schema(@fields)

      @cast_fields cast_fields(@fields)
      @required_fields required_fields(@fields)

      @impl true
      def changeset(state, params) do
        state
        |> cast(params, @cast_fields)
        |> validate_required(@required_fields)
      end
    end
  end

  defmacro translate_to_schema(fields) do
    quote bind_quoted: [fields: fields] do
      embedded_schema do
        Enum.map(fields, fn
          [name, type, opts] ->
            field(name, type, opts)

          [name, type] ->
            field(name, type)
        end)

        timestamps()
      end
    end
  end

  def cast_fields(fields), do: filtered_field(fields, filter(:cast))

  def required_fields(fields), do: filtered_field(fields, filter(:required))

  def filtered_field(fields, filter_fun) do
    Enum.reduce(fields, [], fn
      [name | _tail] = record, acc ->
        if filter_fun.(record), do: [name | acc], else: acc

      _, acc ->
        acc
    end)
  end

  def filter(field) do
    fn
      [_, _, opts] -> Keyword.get(opts, field, false)
      _ -> false
    end
  end
end
