defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(_arg) do
    DynamicSupervisor.start_child(__MODULE__, Pooly.SampleWorker)
  end

  @impl true
  def init(_arg) do
    opts = [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end
end
