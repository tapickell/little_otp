defmodule Pooly do
  use Application

  def start(_type, _args) do
    config = [
      [name: "Pool1", size: 2],
      [name: "Pool2", size: 3],
      [name: "Pool3", size: 4]
    ]

    start_pools(config)
  end

  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  def checkin(w_pid) do
    Pooly.Server.checkin(w_pid)
  end

  def checkout() do
    Pooly.Server.checkout()
  end

  def status() do
    Pooly.Server.status()
  end
end
