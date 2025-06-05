# app/controllers/api/v1/weather_controller.rb
module Api
  module V1
    class WeatherController < ApplicationController
      def forecast
        address = params[:address]

        if address.blank?
          render json: { error: "Address is required" }, status: :bad_request
          return
        end

        weather_service = WeatherService.new
        forecast = weather_service.get_forecast(address)

        if forecast
          from_cache = forecast.delete(:from_cache)
          render json: {
            data: forecast,
            meta: {
              cached: from_cache,
              cache_time: from_cache ? "30 minutes" : nil
            }
          }
        else
          render json: { error: "Could not retrieve weather forecast" }, status: :service_unavailable
        end
      end
    end
  end
end
