# frozen_string_literal: true

module GoogleMapApi
  # Asks the Google Directions API for the driving distance of a route that
  # starts at the gogetter, visits every job and ends at the last one.
  class CalculateDistanceService
    DIRECTIONS_URL = 'https://maps.googleapis.com/maps/api/directions/json'

    # total_distance is in metres; job_routes is in the order Google drove.
    Route = Data.define(:total_distance, :job_routes)

    class Error < StandardError; end
    # No drivable route between the given points.
    class RouteNotFound < Error; end
    # Rate or daily quota used up; retrying later can succeed.
    class QuotaExceeded < Error; end
    # Google refused the request itself: bad, restricted or unbilled key.
    class RequestDenied < Error; end
    # Google failed or answered with something that is not a Directions reply.
    class Unavailable < Error; end

    STATUS_ERRORS = {
      'ZERO_RESULTS' => RouteNotFound,
      'NOT_FOUND' => RouteNotFound,
      'MAX_ROUTE_LENGTH_EXCEEDED' => RouteNotFound,
      'OVER_QUERY_LIMIT' => QuotaExceeded,
      'OVER_DAILY_LIMIT' => QuotaExceeded,
      'REQUEST_DENIED' => RequestDenied,
      'INVALID_REQUEST' => RequestDenied,
      'MAX_WAYPOINTS_EXCEEDED' => RequestDenied
    }.freeze

    attr_reader :job_routes, :gogetter_location

    def initialize(job_routes, gogetter_location)
      @job_routes = job_routes
      @gogetter_location = gogetter_location
    end

    def call
      *waypoints, destination = job_routes
      return if destination.nil?

      query = {
        mode: 'driving',
        departure_time: Time.current.to_i,
        traffic_model: 'best_guess',
        key: google_api_key,
        origin: lat_long(gogetter_location),
        destination: lat_long(destination)
      }
      query[:waypoints] = [ 'optimize:true', *waypoints.map { |stop| lat_long(stop) } ].join('|') if waypoints.any?

      route = fetch_route(query)
      Route.new(
        total_distance: route['legs'].sum { |leg| leg.dig('distance', 'value') },
        job_routes: [ *in_driven_order(waypoints, route['waypoint_order']), destination ]
      )
    end

    private

    def fetch_route(query)
      response = HTTParty.get(DIRECTIONS_URL, query: query)
      raise Unavailable, "Directions API answered HTTP #{response.code}" unless response.success?

      body = parse(response)
      status = body['status']
      raise STATUS_ERRORS.fetch(status, Unavailable), "Directions API status #{status || 'missing'}" unless status == 'OK'

      route = body.dig('routes', 0)
      raise RouteNotFound, 'Directions API returned OK without a route' unless route.is_a?(Hash) && route['legs'].is_a?(Array)

      route
    end

    def parse(response)
      body = response.parsed_response
      raise Unavailable, 'Directions API returned a non-JSON body' unless body.is_a?(Hash)

      body
    rescue JSON::ParserError
      raise Unavailable, 'Directions API returned malformed JSON'
    end

    def lat_long(location)
      "#{location[:lat]},#{location[:long]}"
    end

    # optimize:true lets Google reorder the waypoints. The distance it returns
    # is for its order, so the stops have to be reported in that order too.
    def in_driven_order(waypoints, waypoint_order)
      return waypoints unless waypoint_order.is_a?(Array) && waypoint_order.sort == waypoints.each_index.to_a

      waypoint_order.map { |index| waypoints[index] }
    end

    def google_api_key
      ENV.fetch('GOOGLE_API_KEY') do
        raise KeyError, 'GOOGLE_API_KEY is not set. Copy .env.example to .env and add a key ' \
                        'with the Directions API enabled.'
      end
    end
  end
end
