defmodule Peasant.Repo do
  alias Peasant.Storage.Keeper

  def get(id, domain) do
    domain
    |> String.to_existing_atom()
    |> Cachex.get(id)
    |> case do
      {:ok, record} -> record
      error -> error
    end
  end

  def put(record, id, domain, persist \\ true) do
    record = if persist, do: Keeper.persist(record, domain), else: record

    domain
    |> String.to_existing_atom()
    |> Cachex.put(id, record)
  end

  def list(domain) do
    domain
    |> String.to_existing_atom()
    |> Cachex.stream!()
    |> Stream.map(fn {_, _key, _, _, value} -> value end)
    |> Enum.to_list()
  end

  def clear(domain) do
    {:ok, _} =
      domain
      |> String.to_existing_atom()
      |> Cachex.clear()

    :ok
  end
end
