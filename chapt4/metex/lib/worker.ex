defmodule Metex.Worker do
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:location, location}, _from, state) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_state = update_location_count(state, location)
        {:reply, temp, new_state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp update_location_count(state, location) do
    if Map.has_key?(state, location) do
      Map.update!(state, location, &(&1 + 1))
    else
      Map.put_new(state, location, 1)
    end
  end

  defp temperature_of(location) do
    location
    |> url_for()
    |> HTTPoison.get()
    |> parse_get_response()
    |> create_user_response(location)
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{URI.encode(location)}&appid=#{apikey()}"
  end

  defp parse_get_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> Jason.decode!()
    |> compute_temperature
  end

  defp parse_get_response(_), do: :error

  defp create_user_response({:ok, temp}, location) do
    {:ok, "#{location}: #{temp} ℃"}
  end

  defp create_user_response(:error, location) do
    Logger.warn("#{location} not found")
    :error
  end

  defp compute_temperature(%{"main" => %{"temp" => temperature}}) do
    {:ok, (temperature - 273.15) |> Float.round(1)}
  end

  defp compute_temperature(_), do: :error

  defp apikey do
    "24f5ff8e85a7a95f6d119d2534ef4c4e"
  end
end
