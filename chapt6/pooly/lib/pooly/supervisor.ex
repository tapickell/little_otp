defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init([{:size, size}]) do
    children = [
      Pooly.Server.child_spec(sup: self(), size: size)
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
