defmodule Panel.Tools.Action.ConfigurationTemplateOption do
  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Ecto.Type

  @derive Jason.Encoder

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:code, :string, autogenerate: false}
  @foreign_key_type :string
  embedded_schema do
    field(:label, :string)
    field(:hint, :string, default: "")
    field(:description, :string, default: "")
    field(:type, :string)
    field(:required, :boolean, default: false)
  end

  def changeset(option, attrs) do
    option
    |> cast(attrs, [:code, :label, :hint, :description, :type, :required])
    |> validate_required([:code, :label, :type, :required])
    |> validate_type(:type)
  end

  @allowed_types ["string", "integer", "float"]

  def validate_type(changeset, field, opts \\ []) do
    validate_change(changeset, field, fn
      _field, type when type in @allowed_types ->
        []

      _field, type ->
        [
          {
            field,
            {
              message(opts, "type unknown"),
              [validation: :type, value: type]
            }
          }
        ]
    end)
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end

  @impl true
  def type, do: :map

  @impl true
  def cast(%__MODULE__{} = option), do: {:ok, option}

  def cast(%{} = attrs) do
    case __MODULE__.changeset(%__MODULE__{}, attrs) do
      %{valid?: false, errors: errors} -> {:error, errors}
      changeset -> changeset |> Ecto.Changeset.apply_changes()
    end
    |> cast()
  end

  def cast(_), do: :error

  @impl true
  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct!(__MODULE__, data)}
  end

  @impl true
  def dump(%__MODULE__{} = option), do: {:ok, Map.from_struct(option)}
  def dump(_), do: :error

  @impl true
  def equal?(left, right), do: left == right

  @impl true
  def embed_as(_), do: :self
end
