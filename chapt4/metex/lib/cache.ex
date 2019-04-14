defmodule Metex.Cache do
  use GenServer

  require Logger

  @server_name MCache
  @table_name :metex_cache

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, @table_name, opts ++ [name: MCache])
  end

  def write(key, data) do
    GenServer.cast(@server_name, {:write, {key, data}})
  end

  def read(key) do
    GenServer.call(@server_name, {:read, key})
  end

  def delete(key) do
    GenServer.cast(@server_name, {:delete, key})
  end

  def clear() do
    GenServer.cast(@server_name, :clear)
  end

  def stop() do
    GenServer.cast(@server_name, :stop)
  end

  def exists?(key) do
    GenServer.call(@server_name, {:exists, key})
  end

  def init(table_name) do
    table = :ets.new(table_name, [:named_table, read_concurrency: true])
    {:ok, table}
  end

  def handle_call({:read, key}, _from, table) do
    case :ets.lookup(table, key) do
      [{^key, data}] -> {:reply, data, table}
      [] ->
        Logger.warn("Data for #{key} not found in #{@table_name}")
        {:reply, :error, table}
    end
  end

  def handle_call({:exists, key}, _from, table) do
    reply = :ets.member(table, key)
    {:reply, reply, table}
  end

  def handle_cast({:write, {key, data}}, table) do
    handle_ets_cast(:insert).(:ets.insert(table, {key, data}))
    {:noreply, table}
  end

  def handle_cast({:delete, key}, table) do
    handle_ets_cast(:delete).(:ets.delete(table, key))
    {:noreply, table}
  end

  def handle_cast(:clear, table) do
    handle_ets_cast(:delete_all).(:ets.delete_all_objects(table))
    {:noreply, table}
  end

  def handle_cast(:stop, _table) do
    {:stop, :normal, nil}
  end

  def handle_info(msg, table) do
    Logger.info("Received: #{inspect(msg)}")
    {:noreply, table}
  end

  def terminate(reason, table) do
    handle_ets_cast(:delete_all).(:ets.delete(table))
    Logger.warn("Server terminated b/c of #{inspect(reason)}")
    :ok
  end

  defp handle_ets_cast(action) do
    fn(response) ->
      Logger.info("#{inspect(action)} on table #{inspect(@table_name)} #{inspect(msg(response))}")
    end
  end

  defp msg(true), do: :success
  defp msg(_), do: :failure

end
