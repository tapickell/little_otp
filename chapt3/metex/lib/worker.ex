defmodule Metex.Worker do
  def loop do
    receive do
      {sender_pid, location} ->
        send(sender_pid, {:ok, temperature_of(location)})
      _ ->
        IO.puts "Don't know how to process this message"
    end
    loop()
  end

  def temperature_of(location) do
    location
    |> url_for
    |> HTTPoison.get
    |> parse_get_response
    |> create_user_response(location)
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{URI.encode(location)}&appid=#{apikey()}"
  end

  defp parse_get_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!
    |> compute_temperature
  end
  defp parse_get_response(_), do: :error

  defp create_user_response({:ok, temp}, location), do: "#{location}: #{temp} ℃"
  defp create_user_response(:error, location), do: "#{location} not found"

  defp compute_temperature(%{"main" => %{"temp" => temperature}}) do
    {:ok, (temperature - 273.15) |> Float.round(1)}
  end
  defp compute_temperature(_), do: :error

  defp apikey do
    "24f5ff8e85a7a95f6d119d2534ef4c4e"
  end
end
