defmodule Panel.Tools.Tool.Config do
  defmacro __using__(_env) do
    quote do
      use Ecto.Schema

      Module.register_attribute(__MODULE__, :config_keys, accumulate: true)
      Module.register_attribute(__MODULE__, :config_labels, accumulate: true)
      Module.register_attribute(__MODULE__, :config_hints, accumulate: true)
      Module.register_attribute(__MODULE__, :config_descriptions, accumulate: true)
    end
  end

  defmacro key(name, type \\ :string, opts \\ []) do
    quote do
      Panel.Tools.Tool.Config.__key__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  def __field__(mod, name, type, opts) do
    label = opts[:label] || Atom.to_string(name)
    description = opts[:description] || ""
    hint = opts[:hint] || ""
    required? = opts[:required] || false
  end
end
