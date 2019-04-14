defmodule Ring do

  def create_processes(n) do
    Enum.map(1..n, fn _ -> spawn(fn -> loop() end) end)
  end

  def loop() do
    receive do
      {:link, link_to} when is_pid(link_to) ->
        Process.link(link_to)
        loop()

      :trap_exit ->
        Process.flag(:trap_exit, true)
        loop()

      :crash -> 1/0

      {:EXIT, pid, reason} ->
        IO.puts("#{inspect(self())} received {:EXIT, #{inspect(pid)}, #{reason}}")
        loop()
    end
  end

  def link_processes(procs), do: link_processes(procs, [])

  def link_processes([p1, p2 | rest], linked) do
    send(p1, {:link, p2})
    link_processes([p2 | rest], [p1 | linked])
  end

  def link_processes([last_p | []], linked) do
    first_p = List.last(linked)
    send(last_p, {:link, first_p})
    [last_p | linked]
  end
end
