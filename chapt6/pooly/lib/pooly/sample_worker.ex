defmodule Pooly.SampleWorker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  defdelegate stop(pid), to: GenServer

  def init(_arg) do
    {:ok, nil}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
