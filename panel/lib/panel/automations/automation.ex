defmodule Panel.Automations.Automation do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:uuid, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  embedded_schema do
    field(:name, :string)

    timestamps()
  end

  @cast_fields ~w(
    uuid
    name
  )a

  @required_fields ~w(
    name
  )a

  def new(attrs) do
    with(
      %{valid?: true} = changeset <- cast(%__MODULE__{}, attrs, @cast_fields),
      %{valid?: true} = changeset <- validate_required(changeset, @required_fields)
    ) do
      changeset

      # unless unquote(no_config),
      #   do: cast_embed(changeset, :config)
    else
      %{valid?: false, errors: errors} -> {:error, errors}
      error -> {error, :unknown_error, error}
    end
  end
end
