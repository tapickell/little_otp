defmodule Pooly.PoolsSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    opts = [
      strategy: :one_for_one
    ]

    Supervisor.init([], opts)
  end

end
