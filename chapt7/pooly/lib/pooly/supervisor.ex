defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  @impl true
  def init(pools_config) do
    children = Enum.map(pools_config, fn([name: n, size: s]) ->
      Pooly.Server.child_spec(sup: self(), id: n, name: n, size: s)
    end)

    Supervisor.init(children, strategy: :one_for_all)
  end
end
