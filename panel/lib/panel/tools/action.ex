defmodule Panel.Tools.Action do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Panel.Tools.Action.ConfigurationTemplateOption

  @derive Jason.Encoder

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:code, :string, autogenerate: false}
  @foreign_key_type :string
  embedded_schema do
    field(:name, :string, null: false)
    field(:configuration_template, {:map, ConfigurationTemplateOption}, default: %{})
    field(:events, {:array, :string})
  end

  @doc false
  def changeset(action, attrs) do
    action
    |> cast(attrs, [:code, :name, :configuration_template, :events])
    |> validate_required([:code, :name])

    # |> cast_embed(, with: &ConfigurationTemplateOption.changeset/2)
  end

  def new(attrs) do
    case changeset(%__MODULE__{}, attrs) do
      %{valid?: false, errors: errors} ->
        {:error, errors}

      changeset ->
        Ecto.Changeset.apply_changes(changeset)
    end
  end

  def prepare_actions(raw_actions) when is_list(raw_actions) do
    raw_actions
    |> Enum.map(fn raw_action ->
      %Panel.Tools.Action{} = new(raw_action)
    end)
  end
end
