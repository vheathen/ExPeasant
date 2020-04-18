defmodule Panel.Tools.Tool do
  @moduledoc false

  @callback actions_list() ::
              [%Panel.Tools.Action{}]

  @callback maybe_attach(tool_config :: term) ::
              :ok
              | {:error, :already_attached}
              | {:error, :config_error, list(term)}

  @callback detach(tool_config :: term) ::
              :ok
              | {:error, :no_tool_found}

  @callback do_action(
              tool :: struct(),
              action_name :: String.t(),
              action_config :: term()
            ) ::
              :ok
              | {:error, :no_tool_with_given_uuid}
              | {:error, :no_such_active_action_exists}

  defmacro __using__(env) do
    _no_config = Keyword.get(env, :no_config, false)

    quote do
      use Ecto.Schema
      import Ecto.Changeset

      import Panel.Notifications

      @domain :tools

      @behaviour Panel.Tools.Tool

      @type t() :: __MODULE__

      @current_version 1

      @timestamps_opts [type: :utc_datetime_usec]
      @primary_key {:uuid, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      embedded_schema do
        field(:version, :integer, null: false, default: @current_version)
        field(:name, :string)

        # unless unquote(no_config),
        #   do: embeds_one(:config, __MODULE__.Config, on_replace: :delete)

        field(:config, :map, default: %{})

        field(:placement, :string)
        field(:attached, :boolean, default: false)
        field(:active, :boolean, default: false)
        field(:visible, :boolean, default: false)

        timestamps()
      end

      @cast_fields ~w(
        config

        uuid
        version
        name
        placement
        attached
        active
        visible
      )a

      @required_fields ~w(
        version
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

      def upgrade(%__MODULE__{version: @current_version} = tool), do: tool

      def upgrade(%__MODULE__{version: version}),
        do:
          raise(ArgumentError,
            message: "don't know how to upgrade #{%__MODULE__{}} from version #{version}"
          )
    end
  end
end
