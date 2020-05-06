defmodule Peasant.Automation.State.Step do
  use Peasant.Schema

  @action "action"
  @awaiting "awaiting"

  @allowed_types [
    @action,
    @awaiting
  ]

  embedded_schema do
    field(:description, :string)
    field(:type, :string, default: @action)
    field(:time_to_wait, :integer)
    field(:tool_uuid, :binary_id)
    field(:action, :any, virtual: true)
    field(:action_config, :map)
    field(:wait_for_events, :boolean, default: false)
    field(:active, :boolean, default: false)
    field(:suspended_by_tool, :boolean, default: false)

    timestamps()
  end

  def required(type \\ "common")

  def required(@action),
    do: ~w(
        tool_uuid
        action
      )a ++ required()

  def required(@awaiting),
    do: ~w(
        time_to_wait
      )a ++ required()

  def required(_),
    do: ~w(
        type
      )a

  def not_required(type \\ "common")

  def not_required(@action),
    do: ~w(
        action_config
        wait_for_events
      )a ++ not_required()

  def not_required(_),
    do: ~w(
        description
        active
      )a

  @impl Peasant.Schema
  def changeset(state, %{type: type} = params) do
    state
    |> cast(params, not_required(type) ++ required(type))
    |> validate_required(required(type))
    |> validate_type(:type)
    |> maybe_validate_action()
    |> maybe_validate_time_to_wait()
  end

  def changeset(state, params) do
    params = params |> Enum.into(%{}) |> Map.put(:type, @action)
    changeset(state, params)
  end

  def validate_type(changeset, field) do
    validate_change(
      changeset,
      field,
      fn
        _field, type when type in @allowed_types ->
          []

        _field, _action ->
          type_error(field)
      end
    )
  end

  def maybe_validate_time_to_wait(changeset) do
    case fetch_field(changeset, :type) do
      {_, @awaiting} -> validate_number(changeset, :time_to_wait, greater_than: -1)
      _ -> changeset
    end
  end

  def maybe_validate_action(changeset) do
    case fetch_field(changeset, :type) do
      {_, @action} -> validate_action(changeset, :action)
      _ -> changeset
    end
  end

  def validate_action(%{} = changeset, field) do
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

  defp type_error(field),
    do: [{field, {"not a proper step type", [validation: :type]}}]
end
