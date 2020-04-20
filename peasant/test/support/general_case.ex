defmodule Peasant.GeneralCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case

      import Peasant.Helper
      import Peasant.Factory
      import Peasant.Fixture
    end
  end
end
