defmodule Peasant.Automation.State do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string)
    field(:description, :string)
    field(:steps, {:array, :map}, default: [])
    field(:active, :boolean, default: false)
    field(:new, :boolean, default: true, virtual: true)

    timestamps()
  end

  @required_fields ~w(
        name
      )a

  @cast_fields ~w(
        description
      )a ++ @required_fields

  @impl Peasant.Schema
  def changeset(state, params) do
    state
    |> cast(params, @cast_fields)
    |> validate_required(@required_fields)
  end
end
