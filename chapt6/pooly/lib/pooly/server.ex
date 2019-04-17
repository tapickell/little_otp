defmodule Pooly.Server do
  use GenServer

  defmodule State do
    defstruct sup: nil, size: nil, mfa: nil
  end

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: __MODULE__)
  end

  def init([sup, pool_config]) when is_pid(sup) do
    init(pool_config, %State{sup: sup})
  end

  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  def init([_ | rest], state) do
    init(rest, state)
  end

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_info(:start_worker_supervisor, state = %{sup: sup, mfa: _mfa, size: size}) do
    {:ok, w_sup} = Supervisor.start_child(sup, Pooly.WorkerSupervisor.child_spec([restart: :temporary]) )

    workers = 1..size
    |> Enum.map(fn _ ->
      {:ok, pid} = Pooly.WorkerSupervisor.start_child([])
      pid
    end)

    {:noreply, %{state | worker_sup: w_sup, workers: workers}}
  end

end
