defmodule PeasantWeb.ViewHelpers do
  @moduledoc false

  import Phoenix.LiveView.Helpers

  def format_timestamp(%DateTime{} = dt),
    do:
      "~2..0B.~2..0B.~4..0B ~2..0B:~2..0B"
      |> :io_lib.format([
        dt.day,
        dt.month,
        dt.year,
        dt.hour,
        dt.minute
      ])
      |> IO.iodata_to_binary()

  def format_timestamp(any), do: any

  def format_number(number, delimiter \\ " ") do
    number
    |> to_string
    |> String.replace(~r/\d+(?=\.)|\A\d+\z/, fn int ->
      int
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3, 3, [])
      |> Enum.join(delimiter)
      |> String.reverse()
    end)
  end

  @doc """
  Shows a hint.
  """
  def hint(do: block) do
    assigns = %{block: block}

    ~L"""
    <div class="hint">
      <svg class="hint-icon" viewBox="0 0 44 44" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="44" height="44" fill="none"/>
        <rect x="19" y="10" width="6" height="5.76" rx="1" class="hint-icon-fill"/>
        <rect x="19" y="20" width="6" height="14" rx="1" class="hint-icon-fill"/>
        <circle cx="22" cy="22" r="20" class="hint-icon-stroke" stroke-width="4"/>
      </svg>
      <div class="hint-text"><%= @block %></div>
    </div>
    """
  end

  @doc """
  Builds a modal.
  """
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    title = Keyword.fetch!(opts, :title)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts, title: title]
    live_component(socket, PeasantWeb.ModalComponent, modal_opts)
  end
end
