defmodule Peasant.RepoTest do
  use Peasant.GeneralCase
  import Peasant.Collection.TestHelper

  alias Peasant.Repo
  alias Peasant.Collection.Keeper

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@tools)
    Peasant.subscribe(@automations)

    [db: Keeper.db()]
  end

  describe "list(domain) function" do
    @describetag :integration

    setup :collection_setup

    test "should list all objects for the specified domain", %{
      tools: tools,
      automations: automations
    } do
      assert tools == Repo.list(@tools) |> Enum.sort()
      assert automations == Repo.list(@automations) |> Enum.sort()
    end
  end

  describe "get(id, domain) function" do
    @describetag :integration

    setup :collection_setup

    test "should return an object with a given id from a specified domain", %{
      tools: tools,
      automations: automations
    } do
      Enum.each(tools, fn %{uuid: uuid} = tool ->
        assert tool == Repo.get(uuid, @tools)
      end)

      Enum.each(automations, fn %{uuid: uuid} = automation ->
        assert automation == Repo.get(uuid, @automations)
      end)
    end
  end

  describe "clear/1" do
    @describetag :integration

    test "should clear all records on domain" do
      :ok = Repo.clear(@tools)
      assert [] == Repo.list(@tools)

      :ok = Repo.clear(@automations)
      assert [] == Repo.list(@automations)
    end
  end
end
