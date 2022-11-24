module GoogleMapApi
  # Calculate Distance from Google Maps API
  class CalculateDistanceService
    attr_reader :job_routes, :gogetter_location
    attr_accessor :dir_uri

    def initialize(job_routes, gogetter_location)
      @dir_uri = "https://maps.googleapis.com/maps/api/directions/json?mode=driving&departure_time=#{Time.current.to_i}&traffic_model=best_guess&key=#{google_api_key}"
      @job_routes = job_routes
      @gogetter_location = gogetter_location
    end

    def call
      *remaining_destinations, final_destination = job_routes
      return if final_destination.nil?

      dir_uri.concat("&origin=#{gogetter_location[:lat]},#{gogetter_location[:long]}")
      dir_uri.concat("&destination=#{final_destination[:lat]},#{final_destination[:long]}")
      unless remaining_destinations.blank?
        dir_uri.concat('&waypoints=optimize:true')
        remaining_destinations.each do |temp_destination|
          dir_uri.concat("|#{temp_destination[:lat]},#{temp_destination[:long]}")
        end
      end
      total_distance
    end

    private

    def google_api_key
      ENV.fetch('GOOGLE_API_KEY') do
        raise KeyError, 'GOOGLE_API_KEY is not set. Copy .env.example to .env and add a key ' \
                        'with the Directions API enabled.'
      end
    end

    def total_distance
      route_response = HTTParty.get(URI.encode(dir_uri))
      route_response.dig('routes', 0, 'legs').inject(0) do |distance, response|
        distance + response.dig('distance', 'value')
      end
    end
  end
end
