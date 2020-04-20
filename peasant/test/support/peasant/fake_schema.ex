defmodule FakeSchema do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string, default: "Something")

    timestamps()
  end
end

defmodule FakeSchemaWithChangeset do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string, default: "Something")

    timestamps()
  end

  def changeset(fake, params) do
    fake
    |> cast(params, [:name])
  end
end

defmodule FakeSchemaWithChangesetRequired do
  use Peasant.Schema

  embedded_schema do
    field(:name, :string)

    timestamps()
  end

  def changeset(fake, params) do
    fake
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
