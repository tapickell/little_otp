defmodule Pooly.PoolsSupervisor do
  use Supervisor

  def start_link([name: name, size: size, id: id] = opts) do
    IO.inspect(opts, label: "#{__MODULE__}.start_link()")

    Supervisor.start_link(__MODULE__, opts, name: String.to_atom(name))
  end

  def init(_) do
    opts = [
      strategy: :one_for_one
    ]

    Supervisor.init([], opts)
  end

end
