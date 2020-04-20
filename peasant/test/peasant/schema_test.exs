defmodule Peasant.SchemaTest do
  @moduledoc false
  use ExUnit.Case

  # @empty_fake_schema %{
  #   name: "Something"
  # }

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

  describe "Peasant.Schema" do
    test "should set :uuid as primary key with binary_id type" do
      assert FakeSchema.__schema__(:primary_key) == [:uuid]
      assert FakeSchema.__schema__(:type, :uuid) == :binary_id
    end

    test "should have timestaps with :utc_datetime_usec type" do
      assert FakeSchema.__schema__(:autogenerate) == [
               {
                 [:inserted_at, :updated_at],
                 {Ecto.Schema, :__timestamps__, [:utc_datetime_usec]}
               }
             ]
    end

    test "should introduce a `new/1` function returning a full structure" do
      assert %FakeSchema{} = FakeSchema.new(%{})
    end

    test "should have a `new/0` function as with default 'empty map' parameter" do
      assert %FakeSchema{} = FakeSchema.new()
    end

    test "should inject a new uuid into a struct" do
      %FakeSchema{uuid: uuid} = FakeSchema.new(%{})
      assert {:ok, [_, _, _, {:version, 4}, _]} = UUID.info(uuid)
    end

    test "should call a local `changeset/2` function if available and return a full struct" do
      name = Faker.Name.En.name()

      assert %FakeSchemaWithChangeset{name: ^name} = FakeSchemaWithChangeset.new(%{name: name})
    end

    test "`new/1` function should correctly return error on nested `changeset/2` errors" do
      assert {:error, _} = FakeSchemaWithChangesetRequired.new(%{})
    end
  end
end
