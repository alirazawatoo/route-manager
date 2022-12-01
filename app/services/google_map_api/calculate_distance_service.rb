module GoogleMapApi
  # Calculate Distance from Google Maps API
  class CalculateDistanceService
    attr_reader :job_routes, :gogetter_location
    attr_accessor :dir_uri

    def initialize(job_routes, gogetter_location)
      @dir_uri = "https://maps.googleapis.com/maps/api/directions/json?mode=driving&departure_time=#{Time.current.to_i}&traffic_model=best_guess&key=#{GOOGLE_API_KEY}"
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

    GOOGLE_API_KEY = 'AIzaSyBdcqjL5LQaeAG_4nGbuaL3aYcUnTq_pJY'.freeze
    private_constant :GOOGLE_API_KEY

    def total_distance
      route_response = HTTParty.get(URI.encode(dir_uri))
      route_response.dig('routes', 0, 'legs').inject(0) do |distance, response|
        distance + response.dig('distance', 'value')
      end
    end
  end
end
