demodule WeatherService do
  use GenServer

  def handle_call({:temperature, city}, _from, state) do
    # do magic here
  end

  def handle_cast({:email_weather_report, email}, state) do
    # do magic here
  end
end
