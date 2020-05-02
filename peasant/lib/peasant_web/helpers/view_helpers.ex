defmodule PeasantWeb.ViewHelpers do
  @moduledoc false

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
end
