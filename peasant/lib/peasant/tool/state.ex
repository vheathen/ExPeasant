defmodule Peasant.Tool.State do
  @moduledoc """
  A structure template to keep a tool state
  """

  defmacro __using__(_opts) do
    quote do
      use Peasant.Schema

      embedded_schema do
        field(:name, :string)
        field(:config, :map)
        field(:placement, :string)
        field(:attached, :boolean, default: false)
      end

      @cast_fields ~w(
        name
        config
        placement
      )a

      @required_fields ~w(
        name
        config
      )a

      @impl true
      def changeset(state, params) do
        state
        |> cast(params, @cast_fields)
        |> validate_required(@required_fields)
      end
    end
  end
end
