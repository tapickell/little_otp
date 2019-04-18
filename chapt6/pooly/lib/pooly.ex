defmodule Pooly do
  use Application

  def start(_type, _args) do
    start_pool(size: 5)
  end

  def start_pool(pool_config) do
    Pooly.Supervisor.start_link(pool_config)
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
