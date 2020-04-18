defmodule Panel.Tools do
  @moduledoc false

  alias Panel.Notifications

  alias Panel.Repo

  @domain :tools

  @tool_handler_prefix __MODULE__
  @tool_handler_prefix_str Atom.to_string(@tool_handler_prefix)

  def attach_tool(type, %{config: config} = attrs) when is_atom(type) or is_binary(type) do
    handler = get_tool_handler!(type)

    case handler.maybe_attach(config) do
      :ok ->
        uuid = Map.get(attrs, :uuid, UUID.uuid4())

        tool =
          attrs
          |> Map.put(:uuid, uuid)
          |> handler.new()
          |> Repo.persist(:tools)

        Notifications.notify(@domain, :tool_attached, %{tool_uuid: uuid})

        {:ok, tool}

      {:error, error} ->
        {:error, error}

      {:error, error, _} ->
        {:error, error}
    end
  end

  def do_action(tool_uuid, action_name, action_config) do
    %handler{} = tool = Repo.get_by_id(tool_uuid)
    tool = handler.upgrade(tool)
    handler.do_action(tool.config, action_name, action_config)
  end

  @spec get_tools(type :: Panel.Tools.Tool.type(), filter :: nil | fun()) :: {:ok, list()}
  def get_tools(type, filter \\ nil) do
    pipe = prepare_pipe(filter)

    CubDB.select(db(), min_key: {:tools, type, nil}, max_key: {:tool, type, nil, nil}, pipe: pipe)
  end

  defp db(), do: Repo.get_db()

  defp prepare_pipe(nil) do
    prepare_pipe()
  end

  defp prepare_pipe(filter) when is_function(filter) do
    prepare_pipe()
    |> Keyword.put(:filter, filter)
  end

  defp prepare_pipe do
    [
      map: fn {_key, value} -> value end
    ]
  end

  def get_tool_handler(type) when is_atom(type),
    do: type |> Atom.to_string() |> get_tool_handler()

  def get_tool_handler(@tool_handler_prefix_str <> "." <> type),
    do: get_tool_handler(type, @tool_handler_prefix)

  def get_tool_handler("Elixir." <> type),
    do: get_tool_handler(type, "")

  def get_tool_handler(type),
    do: get_tool_handler(type, @tool_handler_prefix)

  def get_tool_handler(type, prefix) when is_binary(type) do
    try do
      module = Module.safe_concat(prefix, type)
      {:module, ^module} = Code.ensure_compiled(module)
      module
    rescue
      _ -> {:error, :no_tool_type_handler_exists}
    end
  end

  def get_tool_handler!(type) when is_binary(type) or is_atom(type) do
    case get_tool_handler(type) do
      {:error, _} -> raise ArgumentError, message: "no '#{type}' tool type handler exists"
      handler -> handler
    end
  end
end
