defmodule Pooly.Server do
  use GenServer

  defmodule State do
    defstruct sup: nil, size: nil, worker_sup: nil, workers: nil, monitors: nil
  end

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def checkin(pool_name, w_pid) do
    GenServer.call(:"#{pool_name}Server", {:checkin, w_pid})
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}Server", :checkout)
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}Server", :status)
  end

  def init(pools_config) do
    Enum.each(pools_config, fn(c) -> send(self(), {:start_pool, c}) end)
  end

  def init([{:sup, sup}, {:size, size}]) when is_pid(sup) and is_integer(size) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    send(self(), :start_worker_supervisor)
    {:ok, %State{sup: sup, size: size, monitors: monitors}}
  end

  def handle_call({:checkin, w_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, w_pid) do
      [{pid, ref}] ->
        with true <- Process.demonitor(ref),
             true <- :ets.delete(monitors, pid) do
          {:noreply, %{state | workers: [pid | workers]}}
        end

      [] ->
        {:noreply, state}
    end
  end

  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_info({:start_pool, pool_config}, state) do
    opts = generate_id(pool_config)

    {:ok, _pool_sup} = pool_config
    |> Pooly.PoolsSupervisor.child_spec(opts)
    |> Supervisor.start_child()

    {:noreply, state}
  end

  def handle_info(:start_worker_supervisor, %{sup: sup, size: size} = state) do
    case Supervisor.start_child(sup, Pooly.WorkerSupervisor.child_spec(restart: :temporary)) do
      {:ok, w_sup} ->
        start_workers(size)
        workers = get_workers(w_sup)

        {:noreply, %{state | worker_sup: w_sup, workers: workers}}

      {:error, {:already_started, w_sup}} ->
        started_worker_count = get_workers(w_sup) |> Enum.count()
        start_workers(size - started_worker_count)
        workers = get_workers(w_sup)

        {:noreply, %{state | worker_sup: w_sup, workers: workers}}
    end
  end

  def handle_info({:DOWN, ref, _, _, _}, %{monitors: monitors, workers: workers} = state) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, %{monitors: monitors, workers: workers} = state) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [start_workers(1) | workers]}}
      [[]] ->
        {:noreply, state}
    end
  end

  defp start_workers(size) when size > 0 do
    1..size
    |> Enum.each(fn _ ->
      {:ok, pid} = Pooly.WorkerSupervisor.start_child([])
      pid
    end)
  end

  defp start_workers(_), do: :ok

  defp get_workers(w_sup) do
    Supervisor.which_children(w_sup)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  defp generate_id([name: name, size: _size]) do
    [:id, :"#{name}Supervisor"]
  end
end
