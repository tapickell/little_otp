defmodule Pooly.Server do
  use GenServer

  defmodule State do
    defstruct sup: nil, size: nil, worker_sup: nil, workers: nil, monitors: nil
  end

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def checkin(w_pid) do
    GenServer.call(__MODULE__, {:checkin, w_pid})
  end

  def checkout() do
    GenServer.call(__MODULE__, :checkout)
  end

  def status() do
    GenServer.call(__MODULE__, :status)
  end

  def init([{:sup, sup}, {:size, size}]) when is_pid(sup) and is_integer(size) do
    monitors = :ets.new(:monitors, [:private])
    send(self(), :start_worker_supervisor)
    {:ok, %State{sup: sup, size: size, monitors: monitors}}
  end

  def handle_call({:checkin, w_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, w_pi) do
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

  def handle_info(:start_worker_supervisor, %{sup: sup, size: size} = state) do
    {:ok, w_sup} =
      Supervisor.start_child(sup, Pooly.WorkerSupervisor.child_spec(restart: :temporary))

    workers =
      1..size
      |> Enum.map(fn _ ->
        {:ok, pid} = Pooly.WorkerSupervisor.start_child([])
        pid
      end)

    {:noreply, %{state | worker_sup: w_sup, workers: workers}}
  end
end
