# frozen_string_literal: true

module GoogleMapApi
  # Asks the Google Directions API for the driving distance of a route that
  # starts at the gogetter and visits every job.
  class CalculateDistanceService
    DIRECTIONS_URL = 'https://maps.googleapis.com/maps/api/directions/json'

    attr_reader :job_routes, :gogetter_location

    def initialize(job_routes, gogetter_location)
      @job_routes = job_routes
      @gogetter_location = gogetter_location
    end

    def call
      *remaining_destinations, final_destination = job_routes
      return if final_destination.nil?

      query = {
        mode: 'driving',
        departure_time: Time.current.to_i,
        traffic_model: 'best_guess',
        key: google_api_key,
        origin: lat_long(gogetter_location),
        destination: lat_long(final_destination)
      }
      if remaining_destinations.any?
        query[:waypoints] = [ 'optimize:true', *remaining_destinations.map { |stop| lat_long(stop) } ].join('|')
      end
      total_distance(query)
    end

    private

    def lat_long(location)
      "#{location[:lat]},#{location[:long]}"
    end

    def google_api_key
      ENV.fetch('GOOGLE_API_KEY') do
        raise KeyError, 'GOOGLE_API_KEY is not set. Copy .env.example to .env and add a key ' \
                        'with the Directions API enabled.'
      end
    end

    def total_distance(query)
      route_response = HTTParty.get(DIRECTIONS_URL, query: query)
      route_response.dig('routes', 0, 'legs').sum { |leg| leg.dig('distance', 'value') }
    end
  end
end
