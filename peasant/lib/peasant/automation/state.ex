defmodule Peasant.Automation.State do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string)
    field(:description, :string)
    field(:steps, {:array, :map}, default: [])
    field(:total_steps, :integer, default: 0, virtual: true)
    field(:last_step_index, :integer, default: -1)
    field(:last_step_started_timestamp, :integer, default: 0)
    field(:active, :boolean, default: false)
    field(:new, :boolean, default: true, virtual: true)
    field(:timer, :any, virtual: true)
    field(:timer_ref, :string, virtual: true)

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
