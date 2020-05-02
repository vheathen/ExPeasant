defmodule Peasant.Repo do
  alias Peasant.Collection.Keeper

  def get(id, domain) do
    domain
    |> String.to_existing_atom()
    |> Cachex.get(id)
    |> case do
      {:ok, record} -> record
      error -> error
    end
  end

  def put(record, id, domain, opts \\ []) do
    record =
      if Keyword.get(opts, :persist, true), do: Keeper.persist(record, domain), else: record

    domain
    |> String.to_existing_atom()
    |> Cachex.put(id, record)

    record
  end

  def list(domain) do
    domain
    |> String.to_existing_atom()
    |> Cachex.stream!()
    |> Stream.map(fn {_, _key, _, _, value} -> value end)
    |> Enum.to_list()
  end

  def list_full(domain) do
    domain
    |> String.to_existing_atom()
    |> Cachex.stream!()
    |> Stream.map(fn {_, key, _, _, value} -> {key, value} end)
    |> Enum.into(%{})
  end

  def clear(domain) do
    {:ok, _} =
      domain
      |> String.to_existing_atom()
      |> Cachex.clear()

    :ok
  end

  def maybe_persist(record, id, domain) do
    id
    |> get(domain)
    |> case do
      {:error, _} = error -> raise "Something happened with repo: #{inspect(error)}"
      ^record -> :ok
      _ -> put(record, id, domain)
    end
  end
end
