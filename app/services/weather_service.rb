# app/services/weather_service.rb
class WeatherService
  BASE_URI = "https://api.weather.gov"

  def initialize
  end

  def get_forecast(address)
    coordinates = get_coordinates(address)

    puts "*" * 40
    puts "coordinates: #{coordinates}"

    coordinates = {
      latitude: coordinates[:latitude].round(3),
      longitude: coordinates[:longitude].round(3)
    }

    return nil unless coordinates

    zip_code = get_zip_code(address)
    cached = false

    # Try to get from cache first
    if zip_code
      cached_forecast = Rails.cache.read("weather_forecast_#{zip_code}")
      if cached_forecast
        cached_forecast[:from_cache] = true
        return cached_forecast
      end
    end

    request_url = "#{BASE_URI}/points/#{coordinates[:latitude]},#{coordinates[:longitude]}"
    puts "*" * 40
    puts "request_url: #{request_url}"
    response = Faraday.get(request_url)

    # If not in cache, fetch from API
    # response = self.class.get("/points", query: {
    #  lat: coordinates[:latitude],
    #  lon: coordinates[:longitude],
    #  exclude: "minutely,hourly,alerts",
    #  units: "imperial",
    #  appid: @api_key
    # })

    puts "*" * 40
    puts "response: #{response}"
    puts "*" * 40
    puts "response.headers: #{response.headers}"
    puts "*" * 40
    puts "response.body: #{response.body}"

    return nil unless response.success?

    # forecastHourly_url = JSON.parse(response.body)["properties"]["forecastHourly"]

    forecast_url = JSON.parse(response.body)["properties"]["forecast"]
    relativeLocation = JSON.parse(response.body)["properties"]["relativeLocation"]

    # puts "*" * 40
    # puts "forecastHourly: #{forecastHourly}"
    puts "*" * 40
    puts "relativeLocation: #{relativeLocation}"

    # response_forecastHourly = Faraday.get(forecastHourly_url)
    response_forecast = Faraday.get(forecast_url)

    puts "*" * 40
    puts "response_forecast.body: #{response_forecast.body}"

    # puts "*" * 40
    # puts "response_forecastHourly.body: #{response_forecastHourly.body}"

    # Parse and format data
    # forecastHourly = parse_forecastHourly(response_forecastHourly.body)
    forecast = parse_forecast(JSON.parse(response_forecast.body), location: relativeLocation)

    puts "*" * 40
    puts "parsed forecast: #{ap forecast}"

    # Cache by zip code if available
    if zip_code
      Rails.cache.write("weather_forecast_#{zip_code}", forecast)
    end

    forecast[:from_cache] = false
    forecast
  end

  private

  def get_coordinates(address)
    results = Geocoder.search(address)
    return nil if results.empty?

    { latitude: results.first.coordinates[0], longitude: results.first.coordinates[1] }
  end

  def get_zip_code(address)
    results = Geocoder.search(address)
    return nil if results.empty?

    # Extract zip/postal code from results
    results.first.postal_code
  end


  def parse_forecastHourly
  end


  def parse_forecast(data, location: relativeLocation)
    periods = data["properties"]["periods"]
    location = location

    puts "*"*40
    puts "periods: #{periods}"
    puts "*"*40
    puts "location: #{location}"


    today = periods.select{|p| p["name"] == "Today"}.first
    tonight = periods.select{|p| p["name"] == "Tonight"}.first

    upcoming_start = 0
    upcoming_start += 1 if today.present?
    upcoming_start += 1 if tonight.present?

    upcoming = periods[upcoming_start..periods.count]

    city = location["properties"]["city"]
    state = location["properties"]["state"]

    puts "*"*40
    puts "today: #{today}"
    puts "*"*40
    puts "tonight: #{tonight}"

    puts "*"*40
    puts "upcoming: #{upcoming}"

    puts "*"*40
    puts "city: #{city}"
    puts "*"*40
    puts "state: #{state}"

    {
      city: city,
      state: state,
      location: "#{city}, #{state}",
      today: today,
      tonight: tonight,
      upcoming: upcoming
    }
  end
end
