defmodule Peasant.Schema do
  @moduledoc false

  import Ecto.Changeset
  alias __MODULE__

  @callback changeset(struct(), map()) :: Ecto.Changeset.t()
  @optional_callbacks changeset: 2

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      use Ecto.Schema
      import Ecto.Changeset
      @before_compile unquote(__MODULE__)

      @timestamps_opts [type: :utc_datetime_usec]
      @primary_key {:uuid, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id

      def new(attrs \\ %{}), do: unquote(__MODULE__).__new__(__MODULE__, attrs)
    end
  end

  def __new__(schema_module, attrs) do
    schema_module
    |> struct()
    |> Schema.__inject_uuid__()
    |> schema_module.changeset(attrs)
    |> apply_action(:insert)
    |> Schema.__parse_apply_result__()
  end

  def __parse_apply_result__({:ok, rec}), do: rec
  def __parse_apply_result__({:error, %{errors: errors}}), do: {:error, errors}
  def __parse_apply_result__(error), do: {:error, :unkown_error, error}

  def __inject_uuid__(%{} = entity), do: cast(entity, %{uuid: UUID.uuid4()}, [:uuid])

  defmacro __before_compile__(_) do
    quote generated: true do
      def changeset(changeset, _), do: changeset
    end
  end
end
