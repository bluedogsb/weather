# app/services/weather_service.rb
class WeatherService
  BASE_URI = "https://api.weather.gov"

  def initialize
  end

  def get_forecast(address)
    address = "#{address}, USA"
    coordinates = get_coordinates(address)

    # puts "*" * 40
    # puts "coordinates: #{coordinates}"

    coordinates = {
      latitude: coordinates[:latitude].round(3),
      longitude: coordinates[:longitude].round(3)
    }

    return nil unless coordinates

    zip_code = get_zip_code(address)
    # puts "*" * 40
    # puts "get_zip_code: #{zip_code}"
    
    # cached = false

    # Try to get from cache first
    if zip_code

      puts "*" * 40
      puts "----- zip_code cache READ: #{zip_code}"

      cached_forecast = Rails.cache.read("weather_forecast_#{zip_code}")
      if cached_forecast
        cached_forecast[:from_cache] = true
        return cached_forecast
      end
    end

    request_url = "#{BASE_URI}/points/#{coordinates[:latitude]},#{coordinates[:longitude]}"
    # puts "*" * 40
    # puts "request_url: #{request_url}"
    response = Faraday.get(request_url)

    # puts "*" * 40
    # puts "response: #{response}"
    # puts "*" * 40
    # puts "response.headers: #{response.headers}"
    # puts "*" * 40
    # puts "response.body: #{response.body}"

    return nil unless response.success?

    # forecastHourly_url = JSON.parse(response.body)["properties"]["forecastHourly"]

    forecast_url = JSON.parse(response.body)["properties"]["forecast"]
    relativeLocation = JSON.parse(response.body)["properties"]["relativeLocation"]

    # puts "*" * 40
    # puts "forecastHourly: #{forecastHourly}"
    # puts "*" * 40
    # puts "relativeLocation: #{relativeLocation}"

    # response_forecastHourly = Faraday.get(forecastHourly_url)
    response_forecast = Faraday.get(forecast_url)

    # puts "*" * 40
    # puts "response_forecast.body: #{response_forecast.body}"

    # puts "*" * 40
    # puts "response_forecastHourly.body: #{response_forecastHourly.body}"

    # Parse and format data
    # forecastHourly = parse_forecastHourly(response_forecastHourly.body)
    forecast = parse_forecast(JSON.parse(response_forecast.body), location: relativeLocation)

    # puts "*" * 40
    # puts "parsed forecast: #{ap forecast}"

    # Cache by zip code if available
    # puts "*" * 40
    # puts "---------- zip_code: #{zip_code}"
    if zip_code
      puts "*" * 40
      puts "----- zip_code cache WRITE: #{zip_code}"

      Rails.cache.write("weather_forecast_#{zip_code}", forecast)
    end

    forecast[:from_cache] = false
    forecast
  end

  private

  def get_coordinates(address)
    geocoder_results = Geocoder.search(address)

    # puts "*"*40 
    # puts "get_coordinates: #{ap geocoder_results}"

    return nil if geocoder_results.empty?

    data = geocoder_results.select{|r| r.data["address"]["country"] == "United States"}.first

    # puts "*"*40 
    # puts "get_coordinates data: #{ap data}"

    if data.present?
      { 
        latitude: data.coordinates[0],
        longitude: data.coordinates[1] 
      }
    else
      {}
    end
  end

  def get_zip_code(address)
    geocoder_results = Geocoder.search(address)

    # puts "*"*40 
    # puts "get_zip_code: #{ap geocoder_results}"

    return nil if geocoder_results.empty?

    result = geocoder_results.select{|r| r.data["address"]["country"] == "United States"}.first
    if result.data["addresstype"] == "postcode"
      postal_code = result.data["name"]
    end

    # puts "*"*40 
    # puts "get_zip_code postal_code: #{postal_code}"

    postal_code
  end


  def parse_forecastHourly
  end


  def parse_forecast(data, location: relativeLocation)
    periods = data["properties"]["periods"]
    location = location

    # puts "*"*40
    # puts "periods: #{periods}"
    # puts "*"*40
    # puts "location: #{location}"


    today = periods.select{|p| p["name"] == "Today"}.first
    tonight = periods.select{|p| p["name"] == "Tonight"}.first

    upcoming_start = 0
    upcoming_start += 1 if today.present?
    upcoming_start += 1 if tonight.present?

    upcoming = periods[upcoming_start..periods.count]

    city = location["properties"]["city"]
    state = location["properties"]["state"]

    # puts "*"*40
    # puts "today: #{today}"
    # puts "*"*40
    # puts "tonight: #{tonight}"

    # puts "*"*40
    # puts "upcoming: #{upcoming}"

    # puts "*"*40
    # puts "city: #{city}"
    # puts "*"*40
    # puts "state: #{state}"

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
