defmodule Peasant.Automation.State.Step do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string)
    field(:description, :string)
    field(:tool_uuid, :binary_id)
    field(:action, :any, virtual: true)
    field(:action_config, :map)
    field(:wait_for_events, :boolean, default: false)
    field(:active, :boolean, default: false)
    field(:suspended_by_tool, :boolean, default: false)

    timestamps()
  end

  @required_fields ~w(
        name
        tool_uuid
        action
      )a

  @cast_fields ~w(
        description
        action_config
        wait_for_events
        active
      )a ++ @required_fields

  @impl Peasant.Schema
  def changeset(state, params) do
    state
    |> cast(params, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_action(:action)
  end

  def validate_action(changeset, field) do
    validate_change(
      changeset,
      field,
      fn
        _field, action when is_atom(action) ->
          check_action(action, field)

        _field, action when is_binary(action) ->
          try do
            action
            |> String.to_existing_atom()
            |> check_action(field)
          catch
            _, _ -> action_error(field)
          end

        _field, _action ->
          action_format_error(field)
      end
    )
  end

  defp check_action(action, field) when is_atom(action) do
    case Code.ensure_compiled(action) do
      {:module, ^action} -> []
      _ -> action_error(field)
    end
  end

  defp action_error(field),
    do: [{field, {"doesn't exist", [validation: :action]}}]

  defp action_format_error(field),
    do: [{field, {"not an atom or string", [validation: :action]}}]
end
